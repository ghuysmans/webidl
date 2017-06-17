%{
    (* Web IDL parser
     * The below rules are based on Editor’s Draft, 1 June 2017
     * https://heycam.github.io/webidl/#idl-grammar 
    *)
    open Ast
    open Keyword

    let to_non_any is_null value =
      if is_null then `Nullable (value :> nullable_non_any) else (value :> non_any)
%}

%start main
%type < Ast.definitions > main
%type < Ast.non_any > nonAnyType
%type < Ast.primitive > primitiveType
%%

main :
    | definitions EOF {  $1 }

definitions :
    | extendedAttributeList definition definitions { ($1, $2) :: $3 }
    |    { [] }

definition :
    | callbackOrInterface    { $1 }
    | namespace   { `Namespace $1 }
    | partial   { `Partial $1 }
    | dictionary   { `Dictionary $1 }
    | enum   { `Enum $1 }
    | typedef   { `Typedef $1 }
    | implementsStatement   { `Implements $1 }

callbackOrInterface :
    | CALLBACK callbackRestOrInterface   { `Callback $2 }
    | interface   { `Interface $1 }

%public argumentNameKeyword :
    | ATTRIBUTE { attribute }
    | CALLBACK { callback }
    | CONST { const }
    | DELETER { deleter }
    | DICTIONARY { dictionary }
    | ENUM { enum }
    | GETTER { getter }
    | IMPLEMENTS { implements }
    | INHERIT { inherit_ }
    | INTERFACE { interface }
    | ITERABLE { iterable }
    | LEGACYCALLER { legacycaller }
    | MAPLIKE { maplike }
    | NAMESPACE { namespace }
    | PARTIAL { partial }
    | REQUIRED { required }
    | SERIALIZER { serializer }
    | SETLIKE { setlike }
    | SETTER { setter }
    | STATIC { static }
    | STRINGIFIER { stringifier }
    | TYPEDEF { typedef }
    | UNRESTRICTED { unrestricted }

callbackRestOrInterface :
    | callbackRest   { `CallbackRest $1 }
    | interface   { `Interface $1 }

interface :
    | INTERFACE IDENTIFIER inheritance LBRACE interfaceMembers RBRACE SEMICOLON  
    { ($2, $3, $5) }
     
partial :
    | PARTIAL partialDefinition   { $2 }

partialDefinition :
    | partialInterface   { `PartialInterface $1 }
    | partialDictionary   { `PartialDictionary $1 }
    | namespace   { `Namespace $1 }

partialInterface :
    | INTERFACE IDENTIFIER LBRACE interfaceMembers RBRACE SEMICOLON   
    { ($2, $4) }

interfaceMembers :
    | extendedAttributeList interfaceMember interfaceMembers   { ($1, $2) :: $3 }
    |    { [] }

interfaceMember :
    | const { `Const $1 } 
    | operation { `Operation $1 }
    | serializer { `Serializer $1 }
    | stringifier { `Stringifier $1 }
    | staticMember { `Static $1 }
    | iterable { `Iterable $1 }
    | readOnlyMember { `ReadOnly $1 }
    | readWriteAttribute { `Attribute $1 }
    | readWriteMaplike { `Maplike $1 }
    | readWriteSetlike { `Setlike $1 }

inheritance :
    | COLON IDENTIFIER   { Some $2 }
    |    { None }

const :
    | CONST constType IDENTIFIER EQUAL constValue SEMICOLON { ($2, $3, $5) }

constValue :
    | booleanLiteral   { `Bool $1}
    | floatLiteral   { `Float $1 }
    | INTVAL   { `Int $1 }
    | NULL   { `Null }

booleanLiteral :
    | TRUE   { true }
    | FALSE   { false }

floatLiteral :
    | FLOATVAL   { $1 }
    | MINUSINFINITY   { neg_infinity }
    | INFINITY   { infinity }
    | NAN    { nan }

constType :
    | primitiveType null   { if $2 then `Nullable ($1 :> const) else ($1 :> const_type) }
    | IDENTIFIER null   { if $2 then `Nullable (`Ident $1) else (`Ident $1)  }

readOnlyMember :
    | READONLY readOnlyMemberRest   { $2 }

readOnlyMemberRest :
    | attributeRest { `AttributeRest $1 }
    | readWriteMaplike { `Maplike $1 }
    | readWriteSetlike { `Setlike $1 }

readWriteAttribute :
    | INHERIT attributeRest   { `Inherit (`AttributeRest $2) }
    | attributeRest { `AttributeRest $1 }

attributeRest :
    | ATTRIBUTE typeWithExtendedAttributes attributeName SEMICOLON { ($2, $3) }

attributeName :
    | attributeNameKeyword { $1 }
    | IDENTIFIER { $1 }

attributeNameKeyword :
    | REQUIRED { required }

readOnly :
    | READONLY { true }
    |  { false }

defaultValue :
    | constValue { `Const $1 }
    | STRING { `String $1 }
    | LBRACKET RBRACKET { `EmptySequence }

operation :
    | returnType operationRest { `NoSpecialOperation($1, $2) }
    | specialOperation { `SpecialOperation $1 }

specialOperation :
    | special specials returnType operationRest 
    { ($1 :: $2, $3, $4) }

specials :
    | special specials { $1 :: $2 }
    |  { [] }

special :
    | GETTER { `Getter }
    | SETTER { `Setter }
    | DELETER { `Deleter }
    | LEGACYCALLER { `Legacycaller }

operationRest :
    | optionalIdentifier LPAR argumentList RPAR SEMICOLON { ($1, $3) }

optionalIdentifier :
    | IDENTIFIER { Some $1 }
    |  { None }

%public argumentList :
    | argument arguments { $1 :: $2 }
    |  { [] }

arguments :
    | COMMA argument arguments { $2 :: $3 }
    |  { [] }

argument :
    | extendedAttributeList OPTIONAL typeWithExtendedAttributes argumentName default 
    { ($1, `Optional($3, $4, $5)) }
    | extendedAttributeList type_ ellipsis argumentName 
    { if $3 then ($1, `Variadic($2, $4)) else ($1, `Fixed($2, $4)) }

argumentName :
    | argumentNameKeyword { $1 }
    | IDENTIFIER { $1 }

ellipsis :
    | ELLIPSIS { true }
    |  { false }

returnType :
    | type_ { $1 :> return_type }
    | VOID { `Void }

stringifier :
    | STRINGIFIER stringifierRest { $2 }

stringifierRest :
    | readOnly attributeRest
     { if $1 then `ReadOnly (`AttributeRest $2) else (`AttributeRest $2) }
    | returnType operationRest { `NoSpecialOperation($1, $2) }
    | SEMICOLON { `None }

serializer :
    | SERIALIZER serializerRest { $2 }

serializerRest :
    | operationRest { `OperationRest $1 }
    | EQUAL serializationPattern SEMICOLON { $2 }
    | SEMICOLON { `None }

serializationPattern :
    | LBRACE serializationPatternMap RBRACE { `PatternMap $2}
    | LBRACKET serializationPatternList RBRACKET { `PatternList $2 }
    | IDENTIFIER { `Ident $1 }

serializationPatternMap :
    | GETTER { `Getter }
    | INHERIT identifiers { `Inherit $2 }
    | IDENTIFIER identifiers { `Identifiers ($1 :: $2) }
    |  { `None }

serializationPatternList :
    | GETTER { `Getter }
    | IDENTIFIER identifiers { `Identifiers ($1 :: $2) }
    |  { `None }

%public identifiers :
    | COMMA IDENTIFIER identifiers { $2 :: $3 }
    |  { [] }

staticMember :
    | STATIC staticMemberRest { $2 }

staticMemberRest :
    | readOnly attributeRest { if $1 then `ReadOnly (`AttributeRest $2) else (`AttributeRest $2) }
    | returnType operationRest { `NoSpecialOperation($1, $2) }

iterable :
    | ITERABLE LT typeWithExtendedAttributes optionalType GT SEMICOLON { ($3, $4) }

optionalType :
    | COMMA typeWithExtendedAttributes  { Some $2 }
    |  { None }

readWriteMaplike :
    | maplikeRest { $1 }

maplikeRest :
    | MAPLIKE LT typeWithExtendedAttributes COMMA typeWithExtendedAttributes GT SEMICOLON 
    { ($3, $5) }

readWriteSetlike :
    | setlikeRest { $1 }

setlikeRest :
    | SETLIKE LT typeWithExtendedAttributes GT SEMICOLON { $3 }

namespace :
    | NAMESPACE IDENTIFIER LBRACE namespaceMembers RBRACE SEMICOLON 
    { ($2, $4) }

namespaceMembers :
    |  { [] }
    | extendedAttributeList namespaceMember namespaceMembers 
    { ($1, $2) :: $3 }

namespaceMember :
    | returnType operationRest { `NoSpecialOperation($1, $2) }
    | READONLY attributeRest { `ReadOnly (`AttributeRest $2) }

dictionary :
    | DICTIONARY IDENTIFIER inheritance LBRACE dictionaryMembers RBRACE SEMICOLON 
    { ($2, $3, $5) }

dictionaryMembers :
    | dictionaryMember dictionaryMembers  { $1 :: $2 }
    |  { [] }

dictionaryMember :
    | extendedAttributeList REQUIRED typeWithExtendedAttributes IDENTIFIER default SEMICOLON 
    { ($1, `Required($3, $4, $5))}
    | extendedAttributeList type_ IDENTIFIER default SEMICOLON 
    { ($1, `NotRequired($2, $3, $4))}
    
partialDictionary :
    | DICTIONARY IDENTIFIER LBRACE dictionaryMembers RBRACE SEMICOLON 
    { ($2, $4) }

default :
    | EQUAL defaultValue { Some $2 }
    |  { None }

enum :
    | ENUM IDENTIFIER LBRACE enumValueList RBRACE SEMICOLON { ($2, $4) }

enumValueList :
    | STRING enumValueListComma { $1 :: $2 }

enumValueListComma :
    | COMMA enumValueListString { $2 }
    |  { [] }

enumValueListString :
    | STRING enumValueListComma { $1 :: $2 }
    |  { [] }

callbackRest :
    | IDENTIFIER EQUAL returnType LPAR argumentList RPAR SEMICOLON 
    { ($1, $3, $5) }

typedef :
    | TYPEDEF typeWithExtendedAttributes IDENTIFIER SEMICOLON { ($2, $3) }

implementsStatement :
    | IDENTIFIER IMPLEMENTS IDENTIFIER SEMICOLON { ($1, $3) }

type_ :
    | singleType { $1 }
    | unionType null { if $2 then `Nullable (`Union $1) else (`Union $1) }

typeWithExtendedAttributes :
    | extendedAttributeList singleType  { ($1, $2) }
    | extendedAttributeList unionType null 
    { if $3 then ($1, `Nullable (`Union $2)) else ($1, (`Union $2)) }

singleType :
    | nonAnyType { $1 :> type_ }
    | ANY { `Any }

unionType :
    | LPAR unionMemberType OR unionMemberType unionMemberTypes RPAR 
    { $2 :: $4 :: $5 }

unionMemberType :
    | extendedAttributeList nonAnyType { `NonAny ($1, $2) }
    | unionType null { if $2 then `Nullable (`Union $1) else (`Union $1) }

unionMemberTypes :
    | OR unionMemberType unionMemberTypes { $2 :: $3 }
    |  { [] }

nonAnyType :
    | promiseType  { `Promise $1 }
    | primitiveType null { to_non_any $2 $1 }
    | stringType null { to_non_any $2 $1 }
    | IDENTIFIER null { to_non_any $2 (`Ident $1)  }
    | SEQUENCE LT typeWithExtendedAttributes GT null { to_non_any $5 (`Sequence $3) }
    | OBJECT null { to_non_any $2 `Object}
    | ERROR_ null { to_non_any $2 `Object}
    | DOMEXCEPTION null { to_non_any $2 `DomException }
    | bufferRelatedType null { to_non_any $2 $1 }
    | FROZENARRAY LT typeWithExtendedAttributes GT null { to_non_any $5 (`FrozenArray $3) }
    | recordType null { to_non_any $2 (`Record $1) }

primitiveType :
    | unsignedIntegerType { $1 }
    | unrestrictedFloatType { $1 }
    | BOOLEAN { `Boolean }
    | BYTE { `Byte }
    | OCTET { `Octet }

unrestrictedFloatType :
    | UNRESTRICTED floatType { `Unrestricted $2 }
    | floatType { $1 :> primitive }

floatType :
    | FLOAT { `Float }
    | DOUBLE { `Double }

unsignedIntegerType :
    | UNSIGNED integerType { `Unsigned $2 }
    | integerType { $1 :> primitive }

integerType :
    | SHORT { `Short }
    | LONG optionalLong { $2 }

optionalLong :
    | LONG { `LongLong }
    |  { `Long }

stringType :
    | BYTESTRING { `ByteString }
    | DOMSTRING { `DOMString }
    | USVSTRING { `USVString }

promiseType :
    | PROMISE LT returnType GT { $3 }

recordType :
    | RECORD LT stringType COMMA typeWithExtendedAttributes GT { ($3, $5) }

null :
    | QUESTION { true }
    |  { false }

%public bufferRelatedType :
    | ARRAYBUFFER { `ArrayBuffer }
    | DATAVIEW { `DataView }
    | INT8ARRAY { `Int8Array }
    | INT16ARRAY { `Int16Array }
    | INT32ARRAY { `Int32Array }
    | UINT8ARRAY { `Uint8Array }
    | UINT16ARRAY { `Uint16Array }
    | UINT32ARRAY { `Uint32Array }
    | UINT8CLAMPEDARRAY { `Uint8Clampedarray }
    | FLOAT32ARRAY { `Float32Array }
    | FLOAT64ARRAY { `Float64Array }

