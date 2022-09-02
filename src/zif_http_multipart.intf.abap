interface ZIF_HTTP_MULTIPART
  public .

  TYPES: ty_parts TYPE STANDARD TABLE OF REF TO zcl_http_entity WITH EMPTY KEY.

  METHODS add
    IMPORTING
      entity        TYPE REF TO zcl_http_entity OPTIONAL
    RETURNING
      VALUE(result) TYPE REF TO zcl_http_entity.

  METHODS get_part
    IMPORTING
      index         TYPE i
    RETURNING
      VALUE(result) TYPE REF TO zcl_http_entity
    RAISING
      zcx_http.

  METHODS get_parts
    RETURNING
      VALUE(result) TYPE ty_parts.

  DATA: boundary TYPE string READ-ONLY.

endinterface.
