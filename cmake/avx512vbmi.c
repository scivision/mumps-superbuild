// most compilers define __AVX512VBMI__ macro, but MSVC doesn't
//
// return value is used how to determine if AVX512VBMI is available on the system
// * 2 if it is not available
// * 0 if it is available by __AVX512VBMI__ macro
// * 1 means it's available, but we need to define __AVX512VBMI__ macro to use it in MUMPS

#include <immintrin.h>

#ifdef _MSC_VER
#  include <intrin.h>
#elif defined(__GNUC__) || defined(__clang__)
#  include <cpuid.h>
#endif

#ifndef __AVX512F__
#error "AVX512F not defined"
#endif

#ifndef __AVX512BW__
#error "AVX512BW not defined"
#endif

#ifndef __AVX512VL__
#error "AVX512VL not defined"
#endif

int main(void) {

  __m256i index = _mm256_setzero_si256();
  __m256i data = _mm256_setzero_si256();
  __m256i result = _mm256_permutexvar_epi8(index, data);
  _mm256_mask_storeu_epi8((void *)0, (__mmask32)0, result);

  int ret = 2;

#ifdef __AVX512VBMI__
   ret = 0;
#elif defined(_MSC_VER) || !defined(__INTEL_LLVM_COMPILER)
// it seems only MSVC Visual Studio has no way to define __AVX512VBMI__ macro,
// but it can be detected by cpuid instruction

  int cpu_info[4];
  __cpuid(cpu_info, 0);
  if (cpu_info[0] >= 7) {
    __cpuidex(cpu_info, 7, 0);
    ret = (cpu_info[2] & (1 << 1)) != 0;
  }
#else
#  error "__AVX512VBMI__ not defined"
#endif

  return ret;

}
