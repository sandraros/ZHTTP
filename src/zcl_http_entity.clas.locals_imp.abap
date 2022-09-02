*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations


CLASS lcl_multipart DEFINITION DEFERRED.
CLASS zcl_http_entity DEFINITION LOCAL FRIENDS lcl_multipart.

CLASS lcl_multipart DEFINITION FINAL.

  PUBLIC SECTION.

    INTERFACES zif_http_multipart.

    CLASS-METHODS create
      IMPORTING
        parent          TYPE REF TO zcl_http_entity
        boundary_prefix TYPE csequence OPTIONAL
        subtype         TYPE csequence DEFAULT 'mixed'
      RETURNING
        VALUE(result)   TYPE REF TO zif_http_multipart.

    METHODS constructor
      IMPORTING
        boundary TYPE csequence OPTIONAL.

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA: parts  TYPE zif_http_multipart=>ty_parts,
          parent TYPE REF TO zcl_http_entity.

    "! Examples: batch_53e8-fab5-7d68, changeset_90cc-2c78-da48
    "! @parameter prefix | prefix like "batch" or "changeset"
    "! @parameter result | boundary
    CLASS-METHODS get_boundary_random
      IMPORTING
        prefix        TYPE csequence
      RETURNING
        VALUE(result) TYPE string .

ENDCLASS.



CLASS lcl_multipart IMPLEMENTATION.

  METHOD constructor.

    zif_http_multipart~boundary = boundary.

  ENDMETHOD.



  METHOD create.

    DATA(multipart) = NEW lcl_multipart( get_boundary_random( boundary_prefix ) ).
    multipart->parent = parent.
    result = multipart.

  ENDMETHOD.



  METHOD get_boundary_random.

    DATA(guid) = to_lower( cl_system_uuid=>create_uuid_c32_static( ) ).
    result = |{ COND #( WHEN prefix IS NOT INITIAL THEN |{ prefix }_| ELSE |{ guid+12(8) }-| ) }{ guid+20(4) }-{ guid+24(4) }-{ guid+28(4) }|.

  ENDMETHOD.



  METHOD zif_http_multipart~add.

    IF entity IS BOUND.
      APPEND entity TO parts.
      result = entity.
    ELSE.
      result = NEW zcl_http_entity( is_request = parent->is_request ).
      APPEND result TO parts.
    ENDIF.

  ENDMETHOD.



  METHOD zif_http_multipart~get_part.

    IF NOT line_exists( parts[ index ] ).
      RAISE EXCEPTION NEW zcx_http( text = |Part { index } does not exist| ).
    ENDIF.
    result = parts[ index ].

  ENDMETHOD.



  METHOD zif_http_multipart~get_parts.

    result = parts.

  ENDMETHOD.
ENDCLASS.
