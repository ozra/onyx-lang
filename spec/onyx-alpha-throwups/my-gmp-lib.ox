
_debug_start_ = true

@[Link("gmp")]

api MyLibGmp
   FOO_CONST = 47

   alias Int = LibC.Int
   alias Long = LibC.Long
   alias ULong = LibC.ULong
   alias SizeT = LibC.SizeT
   alias Double = LibC.Double
   alias BitcntT = ULong

   struct Mpz
      _mp_alloc Int32
      _mp_size  Int32
      _mp_d     Ptr[ULong]

   alias MpzP = Ptr[Mpz]

   -- # Initialization

   fun init = __gmpz_init(x MpzP)
   fun init2 = __gmpz_init2(x MpzP, bits BitcntT)
   fun init_set_ui = __gmpz_init_set_ui(rop Ptr[Mpz], op ULong)
   fun init_set_si = __gmpz_init_set_si(rop Ptr<Mpz>, op Long)
   fun init_set_d = __gmpz_init_set_d(rop MpzP, op Double)
   fun init_set_str = __gmpz_init_set_str(rop MpzP, str Ptr[UInt8], base Int)

   -- # I/O

   fun set_ui = __gmpz_set_ui(rop MpzP, op ULong) -- comment here?
   fun set_si = __gmpz_set_si(rop MpzP, op Long)
   fun set_d = __gmpz_set_d(rop MpzP, op Double)
   fun set_str = __gmpz_set_str(rop MpzP, str Ptr[UInt8], base Int) Int
   fun get_str = __gmpz_get_str(str Ptr[UInt8], base Int, op MpzP) Ptr[UInt8]
   fun get_si = __gmpz_get_si(op MpzP) Long
   fun get_d = __gmpz_get_d(op MpzP) Double

   -- # Arithmetic

   fun add = __gmpz_add(rop MpzP, op1 MpzP, op2 MpzP)
   fun add_ui = __gmpz_add_ui(rop MpzP, op1 MpzP, op2 ULong)

   fun sub = __gmpz_sub(rop MpzP, op1 MpzP, op2 MpzP)
   fun sub_ui = __gmpz_sub_ui(rop MpzP, op1 MpzP, op2 ULong)
   fun ui_sub = __gmpz_ui_sub(rop MpzP, op1 ULong, op2 MpzP)

   fun mul = __gmpz_mul(rop MpzP, op1 MpzP, op2 MpzP)
   fun mul_si = __gmpz_mul_si(rop MpzP, op1 MpzP, op2 Long)
   fun mul_ui = __gmpz_mul_ui(rop MpzP, op1 MpzP, op2 ULong)

   fun fdiv_q = __gmpz_fdiv_q(rop MpzP, op1 MpzP, op2 MpzP)
   fun fdiv_q_ui = __gmpz_fdiv_q_ui(rop MpzP, op1 MpzP, op2 ULong)

   fun fdiv_r = __gmpz_fdiv_r(rop MpzP, op1 MpzP, op2 MpzP)
   fun fdiv_r_ui = __gmpz_fdiv_r_ui(rop MpzP, op1 MpzP, op2 ULong)

   fun neg = __gmpz_neg(rop MpzP, op MpzP)
   fun abs = __gmpz_abs(rop MpzP, op MpzP)

   fun pow_ui = __gmpz_pow_ui(rop MpzP, base MpzP, exp ULong)

   -- # Bitwise operations

   fun bit-and = __gmpz_and(rop MpzP, op1 MpzP, op2 MpzP)
   fun bit-ior = __gmpz_ior(rop MpzP, op1 MpzP, op2 MpzP)
   fun bit-xor = __gmpz_xor(rop MpzP, op1 MpzP, op2 MpzP)
   fun bit-complement = __gmpz_com(rop MpzP, op MpzP)

   fun fdiv_q_2exp = __gmpz_fdiv_q_2exp(q MpzP, n MpzP, b BitcntT)
   fun mul_2exp = __gmpz_mul_2exp(rop MpzP, op1 MpzP, op2 BitcntT)

   -- # Comparison

   fun cmp = __gmpz_cmp(op1 MpzP, op2 MpzP) Int
   fun cmp_si = __gmpz_cmp_si(op1 MpzP, op2 Long) Int
   fun cmp_ui = __gmpz_cmp_ui(op1 MpzP, op2 ULong) Int

   -- # Memory

   fun set_memory_functions = __gmp_set_memory_functions(malloc (SizeT) -> Ptr[Void], realloc (Ptr[Void], SizeT, SizeT) -> Ptr[Void], free (Ptr[Void], SizeT) -> Void )

MyLibGmp.set-memory-functions(
   ((size) -> GC.malloc(size) ),
   (ptr, old_size, new_size) -> GC.realloc(ptr, new_size); end,
   ((ptr, size) -> GC.free(ptr) )
)
