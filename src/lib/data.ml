(* simplified data of ast *)

type primitive = [
  | `Boolean 
  | `Byte 
  | `Octet 
  | `Unrestricted of [ `Float | `Double ]
  | `Float 
  | `Double 
  | `Unsigned of [ `Short | `Long | `Long_long ]
  | `Short 
  | `Long 
  | `Long_long 
] [@@deriving show]

type string_type = [
  | `Bytestring 
  | `Domstring 
  | `Usvstring
] [@@deriving show]

type buffer = [
  | `Arraybuffer 
  | `Dataview 
  | `Int8array 
  | `Int16array 
  | `Int32array 
  | `Uint8array 
  | `Uint16array 
  | `Uint32array 
  | `Uint8clampedarray 
  | `Float32array 
  | `Float64array 
] [@@deriving show]

type ('types, 'return_type) nullable_aux = [
  | primitive
  | string_type
  | buffer
  | `Ident of string
  | `Object
  | `Error
  | `Domexception
  | `Sequence of 'types
  | `Frozen_array of 'types
  | `Record of string_type * 'types
] [@@deriving show]

(* inside nullable *)
type ('types, 'return_type) null_aux = [
  | ('types, 'return_type) nullable_aux 
  | `Union of ('types, 'return_type) non_any_aux list
]

and ('types, 'return_type) non_any_aux = [
  | `Promise of 'return_type
  | ('types, 'return_type) nullable_aux
  | `Nullable of ('types, 'return_type) null_aux
  | `Union of ('types, 'return_type) non_any_aux list
] [@@deriving show]

type ('types, 'return_type) types_aux = [
  |  ('types, 'return_type) non_any_aux
  | `Any
] [@@deriving show]

type  ('types, 'return_type) return_type_aux = [
  | `Void
  |  ('types, 'return_type) types_aux
] [@@deriving show]

type types = (types, return_type) types_aux [@@deriving show]
and return_type = (types, return_type) return_type_aux [@@deriving show]

type non_any = (types, return_type) non_any_aux
type null = (types, return_type) null_aux

type const_value = [
  | `Bool of bool
  | `Float of float
  | `Int of int
  | `Null
] [@@deriving show]

type const_type = [
  | primitive
  | `Ident of string
]  [@@deriving show]

type const = [const_type | `Nullable of const_type] * string * const_value [@@deriving show]

type default_value = [
  | `Const of const_value
  | `String of string
  | `Empty_sequence
] [@@deriving show]

type necessity = [
  | `Optional of default_value option 
  | `Required of [`Variadic | `Fixed]
] [@@deriving show]

type argument_name = [
  | `Attribute   
  | `Callback   
  | `Const   
  | `Deleter   
  | `Dictionary   
  | `Enum   
  | `Getter   
  | `Implements   
  | `Inherit   
  | `Interface   
  | `Iterable   
  | `Legacycaller   
  | `Maplike   
  | `Namespace   
  | `Partial   
  | `Required   
  | `Serializer   
  | `Setlike   
  | `Setter   
  | `Static   
  | `Stringifier   
  | `Typedef   
  | `Unrestricted 
  | `Ident of string
] [@@deriving show]

type argument = {
  extended_attributes : extended_attribute list ;
  type_ : types ;
  name : argument_name ;
  necessity : necessity
} [@@deriving show]

and extended_attribute = [
    | `Argument_list of string * (argument list)
    | `Ident_list of string * (string list)
    | `Named_arg_list of string * string * (argument list)
  ] [@@deriving show]

type attribute = {
  extended_attributes : extended_attribute list ;
  specifiers : [ `Static | `Readonly | `Inherit ] list ;
  type_ : types ;
  name : [ `Ident of string | `Required ] ;
} [@@deriving show]

type special = [
  | `Getter 
  | `Setter 
  | `Deleter 
  | `Legacycaller 
] [@@deriving show]

type operation = { 
  extended_attributes : extended_attribute list ;
  specifiers : [ `Static | special ] list ;
  type_ : return_type ;
  ident : string option ;
  arguments : argument list ;
} [@@deriving show]

type dictionary_member = {
  extended_attributes : extended_attribute list ;
  is_required : bool ;
  type_ : types ;
  ident : string ;
  default : default_value option ;
} [@@deriving show]

type dictionary = {
  extended_attributes : extended_attribute list ;
  ident : string ;
  inheritance : string option ;
  dictionary_members : dictionary_member list;
} [@@deriving show]

type operation_or_attribute = [
  | `Operation of operation
  | `Attribute of attribute
] [@@deriving show]

type namespace_member = operation_or_attribute [@@deriving show]

type namespace = {
  extended_attributes : extended_attribute list ;
  ident : string ;
  namespace_members : namespace_member list;
} [@@deriving show]

type pattern_list = [
  | `Getter
  | `Identifiers of string list
  | `None
] [@@deriving show]

type serializer = [
  | `Operation of operation
  | `Pattern_map of [ pattern_list | `Inherit of string list]
  | `Pattern_list of pattern_list
  | `Ident of string
  | `None
] [@@deriving show]

type interface_member = [
  | `Const of const
  | `Operation  of operation
  | `Serializer of serializer
  | `Stringifier of [ operation_or_attribute | `None ]
  | `Iterable of types * (types option) * (extended_attribute list)
  | `Attribute of attribute
  | `Maplike of types * types * (extended_attribute list)
  | `Setlike of types * (extended_attribute list)
] [@@deriving show]

type interface = {
  extended_attributes : extended_attribute list ;
  ident : string ;
  inheritance : string option ;
  interface_members : interface_member list;
} [@@deriving show]

type partial = [
  | `Interface of interface
  | `Dictionary of dictionary
  | `Namespace of namespace
] [@@deriving show]

type definition = [
  | `Callback of extended_attribute * string * return_type * (argument list)
  | `Callback_interface of interface
  | `Interface of interface
  | `Namespace of namespace
  | `Partial of partial
  | `Dictionary of dictionary
  | `Enum of extended_attribute * string * (string list)
  | `Typedef of extended_attribute * types * string
  | `Implements of extended_attribute * string * string
] [@@deriving show]
