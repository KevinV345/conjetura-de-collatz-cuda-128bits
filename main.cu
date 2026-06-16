//este programa tarda unos aproximados 10.680.176.281.371.302.195.613 años en terminar con los 2.048 cores de una gpt rtx 3050 laptop
//con los 11340000 cores de la supercomputadora El Capitan estimo que tardaria unos 1.946.720.650.933.117.444 como minimimo años

#include <iostream>
#include <math.h>
#include <fstream>
#include <chrono>
struct uint128
{
    uint64_t lo;
    uint64_t hi;
};


inline __host__ __device__ uint128 add(uint128 a, uint128 b)
{
    uint128 r;
    r.lo = a.lo + b.lo;
    r.hi = a.hi + b.hi + (r.lo < a.lo);
    return r;
}

inline __host__ __device__ uint128 sub(uint128 a, uint128 b)
{
    uint128 r;
    r.lo = a.lo - b.lo;
    r.hi = a.hi - b.hi - (a.lo < b.lo);
    return r;
}

inline __host__ __device__ uint128 shr1(uint128 n)
{
    uint128 r;
    r.lo = (n.lo >> 1) | (n.hi << 63);
    r.hi = n.hi >> 1;
    return r;
}

inline __host__ __device__ uint128 shl1(uint128 n)
{
    uint128 r;
    r.hi = (n.hi << 1) | (n.lo >> 63);
    r.lo = n.lo << 1;
    return r;
}

inline __host__ __device__ uint128 mul3(uint128 n)
{
    return add(shl1(n), n);
}

inline __host__ __device__ uint128 add1(uint128 n)
{
    n.hi += (++n.lo == 0);
    return n;
}

inline __host__ __device__ uint64_t odd(uint128 n)
{
    return n.lo & 1;
}
inline __host__ __device__ bool operator==(const uint128& a, const uint128& b)
{
    return a.hi == b.hi && a.lo == b.lo;
}

inline __host__ __device__ bool operator!=(const uint128& a, const uint128& b)
{
    return !(a == b);
}

inline __host__ __device__ uint128 to_uint128(uint64_t x)
{
    return { x, 0 };
}

void print_uint128_c(const uint128& n)
{
    std::cout << "hi=" << n.hi << " lo=" << n.lo << '\n';
}

inline uint128 mul(uint128 a, uint128 b)
{
    uint64_t carry;

    uint128 r;
    r.lo = _umul128(a.lo, b.lo, &carry);

    r.hi = carry;
    r.hi += a.lo * b.hi;
    r.hi += a.hi * b.lo;

    return r;
}

inline std::string to_string(const uint128& n)
{
    if (n.hi == 0 && n.lo == 0) {
        return "0";
    }

    uint128 temp = n;
    std::string s = "";
    while (temp.hi != 0 || temp.lo != 0) {
        uint64_t rem = 0;

        rem = (rem << 32) | (temp.hi >> 32);
        uint64_t q3 = rem / 10;
        rem %= 10;

        rem = (rem << 32) | (temp.hi & 0xFFFFFFFF);
        uint64_t q2 = rem / 10;
        rem %= 10;

        rem = (rem << 32) | (temp.lo >> 32);
        uint64_t q1 = rem / 10;
        rem %= 10;

        rem = (rem << 32) | (temp.lo & 0xFFFFFFFF);
        uint64_t q0 = rem / 10;
        rem %= 10;

        s += (char)('0' + rem);
        
        temp.hi = (q3 << 32) | q2;
        temp.lo = (q1 << 32) | q0;
    }
    std::reverse(s.begin(), s.end());
    return s;
}
void print_uint128(const uint128& n)
{
    std::cout << to_string(n) << '\n';
}


inline __host__ __device__ bool operator>(const uint128& a, const uint128& b)
{
    return (a.hi > b.hi) || (a.hi == b.hi && a.lo > b.lo);
}
inline __host__ __device__ bool operator>=(const uint128& a, const uint128& b)
{
    return (a.hi > b.hi) || (a.hi == b.hi && a.lo >= b.lo);
}
inline __host__ __device__ bool operator<(const uint128& a, const uint128& b)
{
    return (a.hi < b.hi) || (a.hi == b.hi && a.lo < b.lo);
}
uint128 div_host(uint128 n, uint128 d) {
    if (d.hi == 0 && d.lo == 0) {
        std::cerr << "Error: División por cero" << std::endl;
        return {0, 0};
    }

    uint128 quotient = {0, 0};
    uint128 remainder = {0, 0};
    for (int i = 127; i >= 0; i--) {
        remainder = shl1(remainder);
        uint64_t bit = (i >= 64) ? ((n.hi >> (i - 64)) & 1) : ((n.lo >> i) & 1);
        remainder.lo |= bit;
        if (remainder >= d) {
            remainder = sub(remainder, d);
            if (i >= 64) {
                quotient.hi |= (1ULL << (i - 64));
            } else {
                quotient.lo |= (1ULL << i);
            }
        }
    }
    return quotient;
}
inline __host__ __device__ uint128 mul10(uint128 n)
{
    uint128 n2, n8;
    n2.hi = (n.hi << 1) | (n.lo >> 63);
    n2.lo = n.lo << 1;
    n8.hi = (n.hi << 3) | (n.lo >> 61);
    n8.lo = n.lo << 3;
    return add(n8, n2);
}
inline __host__ __device__ uint128 parse_uint128(const char* str)
{
    uint128 res = { 0, 0 };
    int i = 0;
    while (str[i] == ' ' || str[i] == '\t') {
        i++;
    }
    while (str[i] >= '0' && str[i] <= '9')
    {
        uint64_t digit = str[i] - '0';
        res = mul10(res);
        res = add(res, to_uint128(digit));
        i++;
    }

    return res;
}
inline __host__ uint128 parse_uint128(const std::string& str)
{
    return parse_uint128(str.c_str());
}
inline __host__ __device__ uint128& operator++(uint128& n)
{
    n.hi += (++n.lo == 0);
    return n;
}
inline __host__ __device__ uint128 operator++(uint128& n, int)
{
    uint128 temp = n;
    n.hi += (++n.lo == 0);
    return temp;
}
inline __host__ __device__ uint128& operator+=(uint128& a, const uint128& b)
{
    a = add(a, b);
    return a;
}
inline __host__ __device__ uint128 operator+(uint128 a, const uint128& b)
{
    a += b;
    return a;
}
inline __host__ __device__ uint128 collatz(uint128 n)
{
    uint128 half = shr1(n);
    uint128 odd_value = add1(mul3(n));
    uint64_t mask = 0 - (n.lo & 1);
    uint128 r;
    r.lo = half.lo ^ ((half.lo ^ odd_value.lo) & mask);
    r.hi = half.hi ^ ((half.hi ^ odd_value.hi) & mask);
    return r;
}


__global__ void comprobarCollatz(uint128 offset, char* rv, int count) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= count) return;
    
    uint128 ni = offset + to_uint128(i * 2 + 1);
    uint128 n = ni;
    uint128 one = to_uint128(1);
    uint64_t cont = 0;

    uint128 limit = { 0x5555555555555555ULL, 0x5555555555555555ULL };
    
    while (n != one)
    {
        cont++;
        if(cont > 50000){
            rv[i] = 'i'; // interesante
            return;
        }
        if ((n.lo & 1) != 0) {
            if (n.hi > limit.hi || (n.hi == limit.hi && n.lo >= limit.lo)) {
                rv[i] = 'i';// interesante
                return;
            }
        }

        n = collatz(n);
        if (n < ni) { 
            rv[i] = 'n'; // no interesa
            return;
        }
    }
    rv[i] = 'n'; // no interesa
}

int main() {
    int n = 1000000000;

    size_t bytes_rv = n * sizeof(char);
    char *h_rv = new char[n];
    
    uint128 offset;
    std::ifstream archivo_estado_in("estado.txt");
    if (archivo_estado_in.is_open()) {
        std::string ultimo_numero;
        archivo_estado_in >> ultimo_numero;
        offset = parse_uint128(ultimo_numero);
        archivo_estado_in.close();
        std::cout << "Reanudando desde el numero: " << ultimo_numero << std::endl;
    } else {
        offset = parse_uint128("2361183241434822606840");
        std::cout << "Archivo de estado no encontrado. Iniciando desde el inicio por defecto." << std::endl;
    }
    if ((offset.lo & 1) != 0) {
        offset = sub(offset, to_uint128(1));
        std::cout << "Aviso: El offset era impar. Se ajusto a: " << to_string(offset) << std::endl;
    }

    char *d_rv;
    cudaMalloc(&d_rv, bytes_rv);
    
    int threadsPerBlock = 128;
    int blocksPerGrid = (n + threadsPerBlock - 1) / threadsPerBlock;
    while (true) {

        auto inicio = std::chrono::steady_clock::now();
        comprobarCollatz<<<blocksPerGrid, threadsPerBlock>>>(offset, d_rv, n);
        cudaDeviceSynchronize();
        cudaMemcpy(h_rv, d_rv, bytes_rv, cudaMemcpyDeviceToHost);
        
        int interesantes = 0;
        std::ofstream archivo_interesantes("interesantes.txt", std::ios::app);
        
        for (int i = 0; i < n; i++) {
            if (h_rv[i] == 'i') {
                interesantes++;
                uint128 ni = offset + to_uint128(i * 2 + 1);
                archivo_interesantes << to_string(ni) << '\n';
            }
        }
        archivo_interesantes.close();
        
        offset = offset + to_uint128(n * 2);
        std::ofstream archivo_estado_out("estado.txt", std::ios::trunc);
        archivo_estado_out << to_string(offset);
        archivo_estado_out.close();
        
        auto fin = std::chrono::steady_clock::now();
        
        double segundos =
        std::chrono::duration<double>(fin - inicio).count();
        
        double evaluados_por_segundo = (n*2) / segundos;
        double evaluados_anio=evaluados_por_segundo*60*60*24*365.2425;

        uint128 total =
        {
            UINT64_MAX,
            UINT64_MAX
        };
        uint128 restantes=sub(total,offset);

        
        std::cout
        << "Velocidad: "
        << std::fixed
        << evaluados_por_segundo
        << " numeros/s=d terminando en "
        <<to_string(div_host(restantes,to_uint128(evaluados_anio)))
        <<" anios\n";
    }

    cudaFree(d_rv);
    delete[] h_rv;

    return 0;
}