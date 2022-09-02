*"* use this source file for your ABAP unit test classes

CLASS ltc_execute_xpath DEFINITION DEFERRED.
CLASS ltc_ixml_node_coll_to_string DEFINITION DEFERRED.
CLASS ltc_json_path DEFINITION DEFERRED.
CLASS ltc_json_path_to_xpath DEFINITION DEFERRED.
CLASS ltc_json_xml_to_json DEFINITION DEFERRED.

CLASS zcl_http_utility DEFINITION
    LOCAL FRIENDS
        ltc_execute_xpath
        ltc_json_path
        ltc_json_path_to_xpath
        ltc_json_xml_to_json.



CLASS ltc_execute_xpath DEFINITION
      FOR TESTING
      DURATION SHORT
      RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS test FOR TESTING.

    METHODS execute_xpath_on_json_xml
      IMPORTING
        json          TYPE string
        xpath         TYPE string
      RETURNING
        VALUE(result) TYPE string.

ENDCLASS.



CLASS ltc_ixml_node_coll_to_string DEFINITION
      FOR TESTING
      DURATION SHORT
      RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS test FOR TESTING.
ENDCLASS.



CLASS ltc_json_path DEFINITION
      FOR TESTING
      DURATION SHORT
      RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS test_1 FOR TESTING.
    METHODS test_2 FOR TESTING.
    METHODS test_3 FOR TESTING.
    METHODS test_4 FOR TESTING.
    METHODS test_5 FOR TESTING.
    METHODS test_6 FOR TESTING.
    METHODS test_7 FOR TESTING.
    METHODS test_8 FOR TESTING.
    METHODS test_9 FOR TESTING.
    METHODS test_10 FOR TESTING.
ENDCLASS.



CLASS ltc_json_path_to_xpath DEFINITION
      FOR TESTING
      DURATION SHORT
      RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS test_1 FOR TESTING.
    METHODS test_2 FOR TESTING.
    METHODS test_3 FOR TESTING.
    METHODS test_4 FOR TESTING.
    METHODS test_5 FOR TESTING.
    METHODS test_6 FOR TESTING.
    METHODS test_7 FOR TESTING.
    METHODS test_8 FOR TESTING.
    METHODS test_9 FOR TESTING.
    METHODS test_10 FOR TESTING.
ENDCLASS.



CLASS ltc_json_xml_to_json DEFINITION
      FOR TESTING
      DURATION SHORT
      RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS array FOR TESTING.
    METHODS array_empty FOR TESTING.
    METHODS bool FOR TESTING.
    METHODS null FOR TESTING.
    METHODS num FOR TESTING.
    METHODS object FOR TESTING.
    METHODS object_empty FOR TESTING.
    METHODS str FOR TESTING.
ENDCLASS.



CLASS ltc_json_xml_to_json_complex DEFINITION
      FOR TESTING
      DURATION SHORT
      RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS test FOR TESTING.
ENDCLASS.











CLASS ltc_execute_xpath IMPLEMENTATION.

  METHOD execute_xpath_on_json_xml.
    DATA: json_xml TYPE string.

    CALL TRANSFORMATION id SOURCE XML json RESULT XML json_xml.
    DATA(ixml_node_coll) = zcl_http_utility=>execute_xpath( xml = json_xml xpath = xpath ).
    result = zcl_http_utility=>ixml_node_coll_to_string( ixml_node_coll ).

  ENDMETHOD.



  METHOD test.

    DATA(result) = execute_xpath_on_json_xml( json = '[{"aaa":1},2]' xpath = '/*[1]/*[1][name()="object"]/*[@name="aaa"]' ).
    cl_abap_unit_assert=>assert_equals( act = result exp = '1' ).

  ENDMETHOD.

ENDCLASS.



CLASS ltc_ixml_node_coll_to_string IMPLEMENTATION.
  METHOD test.
    DATA(xml) = `<root><tag1>A</tag1><tag2/><tag1>B</tag1></root>`.
    DATA(ixml) = cl_ixml=>create( ).
    DATA(ixml_stream_factory) = ixml->create_stream_factory( ).
    DATA(ixml_istream) = ixml_stream_factory->create_istream_string( xml ).
    DATA(ixml_document) = ixml->create_document( ).
    DATA(ixml_parser) = ixml->create_parser( stream_factory = ixml_stream_factory
                                             istream        = ixml_istream
                                             document       = ixml_document ).
    ixml_parser->parse( ).
    DATA(ixml_node_coll) = ixml_document->get_elements_by_tag_name( 'tag1' ).
    DATA(string) = zcl_http_utility=>ixml_node_coll_to_string( ixml_node_coll ).
    cl_abap_unit_assert=>assert_equals( act = string exp = `` ).
  ENDMETHOD.
ENDCLASS.



CLASS ltc_json_path IMPLEMENTATION.
  METHOD test_1.
    DATA(json) = zcl_http_utility=>execute_json_path( json = '[1,2]' path = '/[1]' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '1' ).
  ENDMETHOD.

  METHOD test_2.
    DATA(json) = zcl_http_utility=>execute_json_path( json = '[1,[2,3]]' path = '/[2]/[2]' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '3' ).
  ENDMETHOD.

  METHOD test_3.
    DATA(json) = zcl_http_utility=>execute_json_path( json = '[{"aaa":1},2]' path = '/[1]/aaa' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '1' ).
  ENDMETHOD.

  METHOD test_4.
    " <object>
    "   <array name="aaa">
    "     <num>
    "       1
    DATA(json) = zcl_http_utility=>execute_json_path( json = '{"aaa":[1,2]}' path = '/aaa/[1]' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '1' ).
  ENDMETHOD.

  METHOD test_5.
    " <object>
    "   <array name="aaa">
    "     <object>
    "       <num name="bbb">
    "         1
    DATA(json) = zcl_http_utility=>execute_json_path( json = '{"aaa":[{"bbb":1},2]}' path = '/aaa/[1]/bbb' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '1' ).
  ENDMETHOD.

  METHOD test_6.
    DATA(json) = zcl_http_utility=>execute_json_path( json = '{"aaa":[1,2]}' path = '/aaa/[1]' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '1' ).
  ENDMETHOD.

  METHOD test_7.
    DATA(json) = zcl_http_utility=>execute_json_path( json = '{"aaa":1}' path = '/aaa' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '1' ).
  ENDMETHOD.

  METHOD test_8.
    DATA(json) = zcl_http_utility=>execute_json_path( json = '{"aaa":{"bbb":1}}' path = '/aaa/bbb' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '1' ).
  ENDMETHOD.

  METHOD test_9.
    DATA(json) = zcl_http_utility=>execute_json_path( json = '[1,2]' path = '/' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '[1,2]' ).
  ENDMETHOD.

  METHOD test_10.
    DATA(json) = zcl_http_utility=>execute_json_path( json = '{"aaa":{"bbb":1}}' path = '/aaa' ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '{"bbb":1}' ).
  ENDMETHOD.
ENDCLASS.



CLASS ltc_json_path_to_xpath IMPLEMENTATION.
  METHOD test_1.
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/[1]' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/array/*[1]' ).
  ENDMETHOD.

  METHOD test_2.
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/[2]/[2]' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/array/*[2][name()="array"]/*[2]' ).
  ENDMETHOD.

  METHOD test_3.
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/[1]/aaa' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/array/*[1][name()="object"]/*[@name="aaa"]' ).
  ENDMETHOD.

  METHOD test_4.
    " <object>
    "   <array name="aaa">
    "     <num>
    "       1
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/aaa/[1]' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/object/array[@name="aaa"]/*[1]' ).
  ENDMETHOD.

  METHOD test_5.
    " <object>
    "   <array name="aaa">
    "     <object>
    "       <num name="bbb">
    "         1
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/aaa/[1]/bbb' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/object/array[@name="aaa"]/*[1][name()="object"]/*[@name="bbb"]' ).
  ENDMETHOD.

  METHOD test_6.
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/aaa/[1]' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/object/array[@name="aaa"]/*[1]' ).
  ENDMETHOD.

  METHOD test_7.
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/aaa' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/object/*[@name="aaa"]').
  ENDMETHOD.

  METHOD test_8.
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/aaa/bbb' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/object/object[@name="aaa"]/*[@name="bbb"]' ).
  ENDMETHOD.

  METHOD test_9.
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/*' ).
  ENDMETHOD.

  METHOD test_10.
    DATA(xpath) = zcl_http_utility=>json_path_to_xpath( '/aaa' ).
    cl_abap_unit_assert=>assert_equals( act = xpath exp = '/object/*[@name="aaa"]' ).
  ENDMETHOD.
ENDCLASS.



CLASS ltc_json_xml_to_json IMPLEMENTATION.

  METHOD array.

    DATA(json) = zcl_http_utility=>json_xml_to_json( `<array><num>1</num><num>2</num></array>` ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '[1,2]' ).

  ENDMETHOD.

  METHOD array_empty.

    DATA(json) = zcl_http_utility=>json_xml_to_json( `<array/>` ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '[]' ).

  ENDMETHOD.

  METHOD bool.

    DATA(json) = zcl_http_utility=>json_xml_to_json( `<bool>true</bool>` ).
    cl_abap_unit_assert=>assert_equals( act = json exp = 'true' ).

  ENDMETHOD.

  METHOD null.

    DATA(json) = zcl_http_utility=>json_xml_to_json( `<null/>` ).
    cl_abap_unit_assert=>assert_equals( act = json exp = 'null' ).

  ENDMETHOD.

  METHOD num.

    DATA(json) = zcl_http_utility=>json_xml_to_json( `<num>1</num>` ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '1' ).

  ENDMETHOD.

  METHOD object.

    DATA(json) = zcl_http_utility=>json_xml_to_json( `<object><num name="a">1</num><num name="b">2</num></object>` ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '{"a":1,"b":2}' ).

  ENDMETHOD.

  METHOD object_empty.

    DATA(json) = zcl_http_utility=>json_xml_to_json( `<object/>` ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '{}' ).

  ENDMETHOD.

  METHOD str.

    DATA(json) = zcl_http_utility=>json_xml_to_json( `<str>""x\\</str>` ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '"\"\"x\\\\"' ).

  ENDMETHOD.

ENDCLASS.



CLASS ltc_json_xml_to_json_complex IMPLEMENTATION.

  METHOD test.

    DATA(json) = zcl_http_utility=>json_xml_to_json( `<array><object><num name="a">1</num><str>""x\\</str><null/><object><num name="a">1</num></object><bool>true</bool><num name="b">1</num></object><num>2</num></array>` ).
    cl_abap_unit_assert=>assert_equals( act = json exp = '[{"a":1,"":"\"\"x\\\\","":null,"":{"a":1},"":true,"b":1},2]' ).

  ENDMETHOD.

ENDCLASS.
