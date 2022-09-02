CLASS zcl_http_entity DEFINITION
  PUBLIC
  CREATE PROTECTED .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_content_type,
        mime_type TYPE string,
        boundary  TYPE string,
        charset   TYPE string,
      END OF ty_content_type .
    TYPES:
      BEGIN OF ty_raw,
        headers TYPE tihttpnvp,
        body    TYPE string,
        method  TYPE string,
        url     TYPE string,
      END OF ty_raw .

    DATA: headers       TYPE tihttpnvp READ-ONLY,
          http_request  TYPE REF TO zcl_http_request READ-ONLY,
          http_response TYPE REF TO zcl_http_response READ-ONLY,
          single_body   TYPE string READ-ONLY,
          is_request    TYPE abap_bool READ-ONLY.

    METHODS constructor
      IMPORTING
        !is_request TYPE abap_bool .

    CLASS-METHODS decode_utf8
      IMPORTING
        !utf8         TYPE xstring
      RETURNING
        VALUE(result) TYPE string .

    CLASS-METHODS decode_base64
      IMPORTING
        !base64       TYPE string
      RETURNING
        VALUE(result) TYPE xstring
      RAISING
        zcx_http .

    METHODS get_body
      RETURNING
        VALUE(result) TYPE string.

    METHODS get_content_type
      RETURNING
        VALUE(result) TYPE ty_content_type .

    METHODS get_header_field
      IMPORTING
        name          TYPE csequence
      RETURNING
        VALUE(result) TYPE string.

    "! <p class="shorttext synchronized" lang="en"></p>
    "!
    "! @parameter boundary_prefix | Could be "batch" or "changeset" with OData <p class="shorttext synchronized" lang="en"></p>
    "! @parameter subtype | Default "mixed" <p class="shorttext synchronized" lang="en"></p>
    "! @parameter result | <p class="shorttext synchronized" lang="en"></p>
    METHODS get_multipart
      RETURNING
        VALUE(result)   TYPE REF TO zif_http_multipart
      RAISING
        zcx_http.

    METHODS get_raw
      RETURNING
        VALUE(result) TYPE string
      RAISING
        zcx_http .

    METHODS parse_body
      IMPORTING
        body TYPE string
      RAISING
        zcx_http.

    METHODS parse_entity_text
      IMPORTING
        entity_text TYPE string
      RAISING
        zcx_http.

    METHODS set_body
      IMPORTING
        body TYPE csequence
      RAISING
        zcx_http.

    METHODS set_content_http_request
      IMPORTING
        request       TYPE REF TO zcl_http_request OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO zcl_http_request.

    METHODS set_content_http_response
      RETURNING
        VALUE(result) TYPE REF TO zcl_http_response.

    METHODS set_content_type
      IMPORTING
        !value TYPE ty_content_type .

    METHODS set_header_field
      IMPORTING
        !name  TYPE csequence
        !value TYPE csequence .

    "! <p class="shorttext synchronized" lang="en"></p>
    "!
    "! @parameter boundary_prefix | Could be "batch" or "changeset" with OData <p class="shorttext synchronized" lang="en"></p>
    "! @parameter subtype | Default "mixed" <p class="shorttext synchronized" lang="en"></p>
    "! @parameter result | <p class="shorttext synchronized" lang="en"></p>
    METHODS set_multipart
      IMPORTING
        boundary_prefix TYPE csequence OPTIONAL
        subtype         TYPE csequence DEFAULT 'mixed'
      RETURNING
        VALUE(result)   TYPE REF TO zif_http_multipart .

    CLASS-METHODS split_at_regex
      IMPORTING
        val           TYPE csequence
        regex         TYPE csequence
        max_splits    TYPE i DEFAULT 0
      RETURNING
        VALUE(result) TYPE string_table .

    METHODS ungzip
      IMPORTING
        !bytes        TYPE xstring
      RETURNING
        VALUE(result) TYPE xstring .

  PROTECTED SECTION.

    METHODS _get_raw
      IMPORTING
        is_top        TYPE abap_bool
      RETURNING
        VALUE(result) TYPE string "ty_raw
      RAISING
        zcx_http.

    METHODS get_start_line
      RETURNING
        VALUE(result) TYPE string .

  PRIVATE SECTION.

    DATA: multipart TYPE REF TO zif_http_multipart.
    METHODS clear_content.

    CLASS-METHODS create_from_text
      IMPORTING
        text          TYPE string
        is_request    TYPE abap_bool
      RETURNING
        VALUE(result) TYPE REF TO zcl_http_entity
      RAISING
        zcx_http.

ENDCLASS.



CLASS zcl_http_entity IMPLEMENTATION.

  METHOD clear_content.

    multipart = VALUE #( ).
    single_body = VALUE #( ).
    http_request = VALUE #( ).
    http_response = VALUE #( ).

  ENDMETHOD.



  METHOD constructor.

    me->is_request = is_request.

  ENDMETHOD.



  METHOD create_from_text.

    result = NEW #( is_request = is_request ).
    result->parse_entity_text( text ).

  ENDMETHOD.



  METHOD decode_base64.
    TRY.
        CALL TRANSFORMATION id SOURCE root = base64 RESULT root = result.
      CATCH cx_root INTO DATA(error).
        RAISE EXCEPTION NEW zcx_http( previous = error ).
    ENDTRY.
  ENDMETHOD.



  METHOD decode_utf8.
    result = cl_abap_codepage=>convert_from( utf8 ).
  ENDMETHOD.



  METHOD get_body.

    result = ''.
    IF multipart IS BOUND.
      LOOP AT multipart->get_parts( ) ASSIGNING FIELD-SYMBOL(<multipart_part>).
*        result = |{ result }{ COND #( WHEN is_top = abap_false OR sy-tabix > 1 THEN |\r\n| ) }--{ multipart->boundary }\r\n|.
        result = |{ result }--{ multipart->boundary }\r\n{ <multipart_part>->_get_raw( is_top = abap_false ) }|.
      ENDLOOP.
      result = |{ result }--{ multipart->boundary }--\r\n\r\n|.
    ELSEIF http_request IS BOUND.
      result = |{ result }{ CAST zcl_http_entity( http_request )->_get_raw( is_top = abap_false ) }|.
    ELSEIF http_response IS BOUND.
      result = |{ result }{ CAST zcl_http_entity( http_response )->_get_raw( is_top = abap_false ) }|.
    ELSE.
      result = |{ result }{ single_body }\r\n|.
    ENDIF.

  ENDMETHOD.



  METHOD get_content_type.

    LOOP AT headers ASSIGNING FIELD-SYMBOL(<header_field>)
        WHERE name CP 'content-type'.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    SPLIT <header_field>-value AT ';' INTO TABLE DATA(content_type_parts).
    result = REDUCE ty_content_type(
        INIT r TYPE ty_content_type
        FOR <content_type_part> IN content_type_parts
        NEXT r = VALUE #( BASE r
                  mime_type = COND #( WHEN r-mime_type IS INITIAL
                                      THEN to_lower( <content_type_part> )
                                      ELSE r-mime_type )
                  boundary  = COND #( LET boundary = substring_after( val = <content_type_part> sub = 'boundary=' case = abap_false ) IN
                                      WHEN boundary IS NOT INITIAL
                                      THEN boundary
                                      ELSE r-boundary )
                  charset   = COND #( LET charset = substring_after( val = <content_type_part> sub = 'charset=' case = abap_false ) IN
                                      WHEN charset IS NOT INITIAL
                                      THEN charset
                                      ELSE r-charset ) ) ).

  ENDMETHOD.



  METHOD get_header_field.

    result = VALUE #( headers[ name = name ]-value OPTIONAL ).

  ENDMETHOD.



  METHOD get_multipart.

    if multipart is not bound.
      raise exception new zcx_http( text = 'No multipart' ).
    endif.
    result = multipart.

  ENDMETHOD.



  METHOD get_raw.
    result = _get_raw( is_top = abap_true ).
  ENDMETHOD.



  METHOD _get_raw.

    IF multipart IS BOUND.
      " Examples: batch_53e8-fab5-7d68, changeset_90cc-2c78-da48
      DATA(content_type) = get_content_type( ).
      content_type-boundary = multipart->boundary.
      set_content_type( content_type ).
    ENDIF.

    result = get_start_line( ).

    DATA(body) = get_body( ).

    set_header_field( name = 'content-length' value = |{ strlen( body ) }| ).

    LOOP AT headers ASSIGNING FIELD-SYMBOL(<header>)
        WHERE name NP 'content-length'.
      result = |{ result }{ <header>-name }: { <header>-value }\r\n|.
    ENDLOOP.

    result = |{ result }\r\n{ body }|.

  ENDMETHOD.



  METHOD get_start_line.

    result = ''.

  ENDMETHOD.



  METHOD parse_body.

    DATA(content_type) = get_content_type( ).
    DATA(content_encoding) = VALUE #( headers[ name = 'content-encoding' ]-value OPTIONAL ).
    TRY.
        DATA(body_decoded) = decode_utf8( decode_base64( body ) ). " the HAR file contains the ungzipped data as base64
      CATCH cx_root.
        body_decoded = body.
    ENDTRY.

    IF content_type-mime_type = 'application/http'.
      IF is_request = abap_true.
        http_request = zcl_http_request=>create_from_text( body_decoded ).
      ELSE.
        http_response = zcl_http_response=>create_from_text( body_decoded ).
      ENDIF.
    ELSEIF content_type-mime_type CP 'multipart/*'.
      DATA(multipart_parts) = split_at_regex( val = body_decoded regex = `--` && content_type-boundary && `(?: *|--)` && |\r\n| ).
      DELETE multipart_parts INDEX lines( multipart_parts ).
      DELETE multipart_parts INDEX 1.
      LOOP AT multipart_parts ASSIGNING FIELD-SYMBOL(<multipart_part>).
        multipart->add( zcl_http_entity=>create_from_text( text = <multipart_part> is_request = is_request ) ).
      ENDLOOP.
    ELSE.
      single_body = body_decoded.
    ENDIF.

  ENDMETHOD.



  METHOD parse_entity_text.

    SPLIT entity_text AT |\r\n\r\n| INTO DATA(top_text) DATA(body).
    SPLIT top_text AT |\r\n| INTO TABLE DATA(top_lines).
    IF top_lines IS INITIAL.
      RAISE EXCEPTION NEW zcx_http( ).
    ENDIF.

    LOOP AT top_lines ASSIGNING FIELD-SYMBOL(<line>).
      DATA(header) = VALUE ihttpnvp( ).
      " be careful, it's possible to have multiple ":" characters e.g. "Location: https://xxxxxxxxxx"
      DATA(name_value) = split_at_regex( val = <line> regex = ': *' max_splits = 2 ).
      header = VALUE #( name  = name_value[ 1 ]
                        value = name_value[ 2 ] ).
      APPEND header TO headers.
    ENDLOOP.

    DATA(content_type) = get_content_type( ).
    IF content_type-mime_type CP 'multipart*'.
      multipart = NEW lcl_multipart( content_type-boundary ).
    ENDIF.

    parse_body( body ).

  ENDMETHOD.



  METHOD set_body.

    clear_content( ).

    me->single_body = body.

  ENDMETHOD.



  METHOD set_content_http_request.

    clear_content( ).

    IF is_request = abap_false.
      RAISE EXCEPTION NEW zcx_http_no_check( ).
    ENDIF.

    IF request IS BOUND.
      http_request = request.
    ELSE.
      http_request = zcl_http_request=>create( ).
    ENDIF.

    set_content_type( VALUE #( mime_type = 'application/http' ) ).

    result = http_request.

  ENDMETHOD.



  METHOD set_content_http_response.

    clear_content( ).

    IF is_request = abap_true.
      RAISE EXCEPTION NEW zcx_http_no_check( ).
    ENDIF.

    http_response = zcl_http_response=>create( ).

    set_content_type( VALUE #( mime_type = 'application/http' ) ).

    result = http_response.

  ENDMETHOD.



  METHOD set_content_type.

    DATA(content_type) = ``.
    IF value-mime_type CP 'multipart/*'.
      content_type = |{ value-mime_type }; boundary={ value-boundary }|.
      IF value-charset IS NOT INITIAL.
        content_type = |{ content_type }; charset={ value-charset }|.
      ENDIF.
    ELSE.
      content_type = value-mime_type.
    ENDIF.
    set_header_field( name = 'Content-Type' value = content_type ).

  ENDMETHOD.



  METHOD set_header_field.

    ASSIGN headers[ name = name ] TO FIELD-SYMBOL(<header>).
    IF sy-subrc = 0.
      <header>-value = value.
    ELSE.
      INSERT VALUE #( name = name value = value ) INTO TABLE headers.
    ENDIF.

  ENDMETHOD.



  METHOD set_multipart.

    clear_content( ).

    multipart = lcl_multipart=>create( parent = me boundary_prefix = boundary_prefix subtype = subtype ).
    set_content_type( VALUE #( mime_type = |multipart/{ subtype }| boundary = multipart->boundary ) ).

    result = multipart.

  ENDMETHOD.



  METHOD split_at_regex.

    FIND ALL OCCURRENCES OF REGEX regex IN val RESULTS DATA(matches).

    " 0 match means 1 segment (split 'ab' at ':' -> 0 match and result is 'ab')
    IF matches IS INITIAL.
      result = VALUE #( ( CONV #( val ) ) ).
    ELSE.
      " 1 match means 2 splits (split 'a:b' at ':' -> 1 match and result is 'a' and 'b'),
      " 2 matches means 3 splits,
      " etc.
      IF max_splits >= 1 AND lines( matches ) >= max_splits.
        DELETE matches FROM max_splits.
      ENDIF.
      DATA(offset) = 0.
      LOOP AT matches ASSIGNING FIELD-SYMBOL(<match>).
        DATA(length) = <match>-offset - offset.
        APPEND substring( val = val off = offset len = length ) TO result.
        offset = <match>-offset + <match>-length.
      ENDLOOP.
      APPEND substring( val = val off = offset len = strlen( val ) - offset ) TO result.
    ENDIF.

  ENDMETHOD.



  METHOD ungzip.

    cl_abap_gzip=>decompress_binary(
      EXPORTING
        gzip_in                    = bytes
*        gzip_in_len                = -1    " Input Length
      IMPORTING
        raw_out                    = result
*        raw_out_len                =     " Output Length
    ).
*      CATCH cx_parameter_invalid_range.    "
*      CATCH cx_sy_buffer_overflow.    "
*      CATCH cx_sy_compression_error.    "

  ENDMETHOD.
ENDCLASS.
