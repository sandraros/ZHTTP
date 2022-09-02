CLASS zcl_http_request DEFINITION
    INHERITING FROM zcl_http_entity
    PUBLIC
    FINAL
    CREATE PROTECTED.

  PUBLIC SECTION.

    DATA: method       TYPE string READ-ONLY,
          url          TYPE string READ-ONLY,
          http_version TYPE string READ-ONLY.

    CLASS-METHODS create
      IMPORTING
        method        TYPE string OPTIONAL
        url           TYPE string OPTIONAL
        version       TYPE string DEFAULT '1.1'
        headers       TYPE tihttpnvp OPTIONAL
        body          TYPE string OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO zcl_http_request
      RAISING
        zcx_http.

    CLASS-METHODS create_from_text
      IMPORTING
        text          TYPE string
      RETURNING
        VALUE(result) TYPE REF TO zcl_http_request
      RAISING
        zcx_http.

    METHODS apply_to_http_request
      IMPORTING
        REQUEST TYPE REF TO if_http_request
      RAISING
        zcx_http.

    METHODS set_method
      IMPORTING
        method TYPE csequence.

    METHODS set_url
      IMPORTING
        url TYPE csequence.

  PROTECTED SECTION.

    METHODS get_start_line REDEFINITION.
*    METHODS _get_raw REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_http_request IMPLEMENTATION.


  METHOD create.
    result = NEW #( is_request = abap_true ).
    IF method IS NOT INITIAL.
      result->method = method.
    ELSE.
      " arbitrary choice
      result->method = 'POST'.
    ENDIF.
    result->url = url.
    result->http_version = version.
    result->headers = headers.
    result->parse_body( body ).
  ENDMETHOD.


  METHOD create_from_text.

    result = NEW #( is_request = abap_true ).

    SPLIT text AT |\r\n| INTO DATA(first_line) data(entity_text).

    result->method = segment( val = first_line sep = ` ` index = 1 ).
    result->url = segment( val = first_line sep = ` ` index = 2 ).
    result->http_version = segment( val = first_line sep = ` ` index = 3 ).

    result->parse_entity_text( entity_text ).

  ENDMETHOD.



  METHOD apply_to_http_request.

    cl_http_utility=>set_request_uri( request = request uri = url ).
    request->set_method( method ).
    " 1.0 -> 1000, 1.1 -> 1001, 1.2 -> 1002 ...
    request->set_version( ( trunc( http_version ) * 1000 ) + ( frac( http_version ) * 10 ) ).
    request->set_header_fields( headers ).
    request->set_cdata( get_body( ) ).

  ENDMETHOD.



  METHOD get_start_line.
    result = |{ method } { url } HTTP/{ http_version }\r\n|.
  ENDMETHOD.


  METHOD set_method.
    me->method = method.
  ENDMETHOD.


  METHOD set_url.
    me->url = url.
  ENDMETHOD.
ENDCLASS.

