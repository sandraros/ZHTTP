CLASS zcx_http DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  INHERITING FROM cx_static_check.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        text     TYPE csequence OPTIONAL
        textid   TYPE sotr_conc OPTIONAL
        previous TYPE REF TO cx_root OPTIONAL.
    METHODS get_text REDEFINITION.
    METHODS get_longtext REDEFINITION.
    DATA text TYPE string.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_http IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor(
        textid   = textid
        previous = previous ).
    me->text = text.
  ENDMETHOD.


  METHOD get_longtext.
    IF text IS INITIAL.
      result = super->get_longtext( ).
    ELSE.
      result = text.
    ENDIF.
  ENDMETHOD.


  METHOD get_text.
    IF text IS INITIAL.
      result = super->get_text( ).
    ELSE.
      result = text.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

