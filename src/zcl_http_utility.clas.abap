CLASS zcl_http_utility DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS build_url
      IMPORTING
        path                 TYPE csequence
        query_string        TYPE tihttpnvp OPTIONAL
        fragment_identifier TYPE csequence OPTIONAL
      RETURNING
        VALUE(result)       TYPE string.

    CLASS-METHODS entity_args_to_query_string
      IMPORTING
        entity        TYPE csequence
      RETURNING
        VALUE(result) TYPE tihttpnvp.

    CLASS-METHODS execute_json_path
      IMPORTING
        json          TYPE csequence
        path          TYPE csequence
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS execute_xpath
      IMPORTING
        xml           TYPE csequence
        xpath         TYPE csequence
      RETURNING
        VALUE(result) TYPE REF TO if_ixml_node_collection.

    CLASS-METHODS ixml_node_coll_to_string
      IMPORTING
        ixml_node_coll TYPE REF TO if_ixml_node_collection
      RETURNING
        VALUE(result)  TYPE string.

    CLASS-METHODS json_xml_to_json
      IMPORTING
        json_xml      TYPE csequence
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS remove_string_bom
      IMPORTING
        string        TYPE csequence
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS json_path_to_xpath
      IMPORTING
        path          TYPE csequence
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.



CLASS zcl_http_utility IMPLEMENTATION.

  METHOD build_url.
    result = path.
    IF query_string IS NOT INITIAL.
      result = result
            && '?'
            && concat_lines_of( sep   = '&'
                                table = REDUCE #( INIT t TYPE string_table
                                                  FOR <line> IN query_string
                                                  NEXT t = VALUE #( BASE t ( |{ <line>-name }={ escape( val = <line>-value format = cl_abap_format=>e_uri_full ) }| ) ) ) ).
    ENDIF.
    IF fragment_identifier IS NOT INITIAL.
      result = result && '#' && fragment_identifier.
    ENDIF.
  ENDMETHOD.



  METHOD entity_args_to_query_string.

    DATA(args) = match( val = entity regex = '[^\(]*(?=\))' ).
    SPLIT args AT ',' INTO TABLE DATA(arg_table).
    result = VALUE #(
            FOR <arg> IN arg_table
            ( name  = segment( val = <arg> sep = '=' index = 1 )
              value = segment( val = <arg> sep = '=' index = 2 ) ) ).

  ENDMETHOD.



  METHOD execute_json_path.

    DATA(json_xml) = ``.
    DATA(json_string) = CONV string( json ).
    CALL TRANSFORMATION id SOURCE XML json_string RESULT XML json_xml.

    DATA(xpath) = json_path_to_xpath( path ).

    DATA(ixml_node_coll) = zcl_http_utility=>execute_xpath( xml = json_xml xpath = xpath ).

    result = zcl_http_utility=>ixml_node_coll_to_string( ixml_node_coll ).

  ENDMETHOD.



  METHOD execute_xpath.

    DATA(xpp) = NEW cl_xslt_processor( ).
    xpp->set_source_string( xml ).
    xpp->set_expression( expression = xpath ).
    xpp->run( ' ' ).

    result = xpp->get_nodes( ).
  ENDMETHOD.



  METHOD ixml_node_coll_to_string.

    DATA(json_xml) = ``.
    CALL TRANSFORMATION zhttp_id_ixml_node_coll
        SOURCE XML `<dummy/>`
        PARAMETERS ixml_node_coll = ixml_node_coll
        OPTIONS xml_header = 'no'
        RESULT XML json_xml.

    json_xml = remove_string_bom( json_xml ).

    DATA(json) = json_xml_to_json( json_xml ).

    IF json CP '"*'.
      result = substring_before( sub = '"' val = substring_after( val = json sub = '"' ) ).
    ELSE.
      result = json.
    ENDIF.

  ENDMETHOD.



  METHOD json_path_to_xpath.
    TYPES: BEGIN OF ty_xpath_segment,
             array_index         TYPE string,
             xml_element_must_be TYPE string,
             property_must_be    TYPE string,
             value               TYPE string,
           END OF ty_xpath_segment,
           ty_xpath_segments TYPE STANDARD TABLE OF ty_xpath_segment WITH EMPTY KEY.


    SPLIT path AT '/' INTO TABLE DATA(json_path_segments).

    DATA(xpath_segments) = VALUE ty_xpath_segments( ).
    DO lines( json_path_segments ) TIMES.
      APPEND INITIAL LINE TO xpath_segments.
    ENDDO.

    LOOP AT json_path_segments ASSIGNING FIELD-SYMBOL(<json_path_segment>).
      DATA(tabix) = sy-tabix.
      ASSIGN xpath_segments[ tabix ] TO FIELD-SYMBOL(<current_xpath_segment>).
      ASSIGN xpath_segments[ tabix - 1 ] TO FIELD-SYMBOL(<previous_xpath_segment>).
      <current_xpath_segment>-array_index = match( val = <json_path_segment> regex = '[^\[]*(?=\])' ).
      IF tabix = lines( json_path_segments ).
        <current_xpath_segment>-xml_element_must_be = '*'.
      ENDIF.
      IF <json_path_segment> NS '['.
        <current_xpath_segment>-property_must_be = <json_path_segment>.
      ENDIF.
      IF <previous_xpath_segment> IS ASSIGNED.
        IF <json_path_segment> CS '['.
          IF <json_path_segment>(1) <> '[' .
            <previous_xpath_segment>-property_must_be = substring_before( val = <json_path_segment> sub = '[' ).
          ENDIF.
          <previous_xpath_segment>-xml_element_must_be = 'array'.
        ELSEIF <json_path_segment> IS NOT INITIAL.
          <previous_xpath_segment>-xml_element_must_be = 'object'.
        ENDIF.
      ENDIF.
    ENDLOOP.

    LOOP AT xpath_segments ASSIGNING FIELD-SYMBOL(<xpath_segment>).
      IF <xpath_segment>-array_index IS NOT INITIAL.
        IF <xpath_segment>-xml_element_must_be = '*'.
          <xpath_segment>-value = |*[{ <xpath_segment>-array_index }]|.
        ELSE.
          <xpath_segment>-value = |*[{ <xpath_segment>-array_index }][name()="{ <xpath_segment>-xml_element_must_be }"]|.
        ENDIF.
      ELSE.
        IF <xpath_segment>-property_must_be IS NOT INITIAL.
          <xpath_segment>-value = |{ <xpath_segment>-xml_element_must_be }[@name="{ <xpath_segment>-property_must_be }"]|.
        ELSE.
          <xpath_segment>-value = <xpath_segment>-xml_element_must_be.
        ENDIF.
      ENDIF.
    ENDLOOP.

    result = '/' && concat_lines_of( sep = '/' table = REDUCE string_table(
            INIT t TYPE string_table
            FOR <xpath_segment_2> IN xpath_segments
            NEXT t = VALUE #( BASE t ( <xpath_segment_2>-value ) ) ) ).

  ENDMETHOD.



  METHOD json_xml_to_json.

    CALL TRANSFORMATION zhttp_json_xml_to_json
        SOURCE XML json_xml
        RESULT XML result
        OPTIONS xml_header = 'no'.

    result = remove_string_bom( result ).

  ENDMETHOD.



  METHOD remove_string_bom.

    DATA(utf_16_bom) = cl_abap_conv_in_ce=>uccp( cl_abap_char_utilities=>byte_order_mark_big )
                    && cl_abap_conv_in_ce=>uccp( cl_abap_char_utilities=>byte_order_mark_little ).
    DATA(offset) = COND #( WHEN string IS NOT INITIAL AND string(1) CA utf_16_bom THEN 1 ELSE 0 ).
    result = string+offset.

  ENDMETHOD.

ENDCLASS.

