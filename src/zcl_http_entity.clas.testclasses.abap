*"* use this source file for your ABAP unit test classes
CLASS ltc_split_at_regex DEFINITION
      FOR TESTING
      DURATION SHORT
      RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS no_split FOR TESTING.
    METHODS two_segments FOR TESTING.
    METHODS max_splits FOR TESTING.
    METHODS last_empty_segment FOR TESTING.
ENDCLASS.
CLASS ltc_split_at_regex IMPLEMENTATION.

  METHOD max_splits.
    DATA(result) = zcl_http_entity=>split_at_regex( val = 'Location: https://domain/path' regex = ': *' max_splits = 2 ).
    cl_abap_unit_assert=>assert_equals( act = result exp = VALUE string_table( ( |Location| ) ( |https://domain/path| ) ) ).
  ENDMETHOD.

  METHOD no_split.
    DATA(result) = zcl_http_entity=>split_at_regex( val = 'test' regex = ': *' ).
    cl_abap_unit_assert=>assert_equals( act = result exp = VALUE string_table( ( |test| ) ) ).
  ENDMETHOD.

  METHOD two_segments.
    DATA(result) = zcl_http_entity=>split_at_regex( val = 'Content-Type: application/json' regex = ': *' ).
    cl_abap_unit_assert=>assert_equals( act = result exp = VALUE string_table( ( |Content-Type| ) ( |application/json| ) ) ).
  ENDMETHOD.

  METHOD last_empty_segment.
    DATA(result) = zcl_http_entity=>split_at_regex( val = 'Content-Type:' regex = ': *' ).
    cl_abap_unit_assert=>assert_equals( act = result exp = VALUE string_table( ( |Content-Type| ) ( || ) ) ).
  ENDMETHOD.

ENDCLASS.
