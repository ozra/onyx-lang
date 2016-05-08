-- Simplest basic defs

trait SomeTrait

flags SomeFlags

type SomeRef

struct SomeStruct

struct AbstractStruct 'abstract

enum SomeEnum


-- Faulty inheritance / declarations:

-- type RefT < SomeStruct  -- reftype can't inherit struct

-- struct ValT < SomeRef  -- struct can't inherit reftype

-- flags FlagT < SomeEnum  -- base-type can only be intergerish

-- enum EnumT < SomeFlags  -- base-type can only be intergerish

-- struct ValA < SomeStruct  - non abstract - fail


-- Ok inheritance:

struct ValV < AbstractStruct

type RefT < SomeRef

enum EnumT < I8

flags FlagsT < I8
    A
    B
    C

-- ext FlagsT
--     A = 1
--     B = 2

-- a = A