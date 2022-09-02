CLASS zcl_http_response DEFINITION
  INHERITING FROM zcl_http_entity
  PUBLIC
  FINAL
  CREATE PROTECTED.

  PUBLIC SECTION.
    DATA: http_version  TYPE string,
          status_code   TYPE i,
          reason_phrase TYPE string.

    CLASS-METHODS create
      IMPORTING
        http_version  TYPE string OPTIONAL
        status        TYPE i OPTIONAL
        status_text   TYPE string OPTIONAL
        headers       TYPE tihttpnvp OPTIONAL
        content       TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO zcl_http_response
      RAISING
        zcx_http.

    CLASS-METHODS create_from_text
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE REF TO zcl_http_response
      RAISING
        zcx_http.

    "! FEATURE NOT DEVELOPED YET <p class="shorttext synchronized" lang="en"></p>
    "!
    "! @parameter xstring | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter result | <p class="shorttext synchronized" lang="en"></p>
    "! @raising zcx_http | <p class="shorttext synchronized" lang="en"></p>
    CLASS-METHODS create_from_xstring
      IMPORTING
        xstring       TYPE xstring
      RETURNING
        VALUE(result) TYPE REF TO zcl_http_response
      RAISING
        zcx_http.

  PROTECTED SECTION.

    METHODS get_start_line REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_http_response IMPLEMENTATION.

  METHOD create.
    result = NEW #( is_request = abap_false ).
    result->http_version = http_version.
    result->status_code = status.
    result->reason_phrase = status_text.
    result->headers = headers.
    result->parse_body( content ).
  ENDMETHOD.



  METHOD create_from_text.

    result = NEW #( is_request = abap_false ).

    SPLIT text AT |\r\n| INTO DATA(first_line) data(entity_text).

    result->http_version = segment( val = first_line sep = ` ` index = 1 ).
    result->status_code = segment( val = first_line sep = ` ` index = 2 ).
    result->reason_phrase = segment( val = first_line sep = ` ` index = 3 ).

    result->parse_entity_text( entity_text ).

  ENDMETHOD.



  METHOD CREATE_FROM_XSTRING.
    constants: cr_lf TYPE x LENGTH 2 VALUE '0D0A'.
    if xstring byte-ca cr_lf.
      data(status_line) = xstring(sy-fdpos).
      " HTTP/1.1 200 OK
    endif.
  ENDMETHOD.



  METHOD get_start_line.
    result = |{ http_version } { status_code } { reason_phrase }\r\n|.
  ENDMETHOD.
ENDCLASS.

