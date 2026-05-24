#include <iostream>
#include <vector>
#include <fstream>
#include <string>
#include <iomanip>
#include <cuda_runtime.h>

using namespace std;

#define CUDA_CHECK(call) do {                                      \
    cudaError_t err = call;                                        \
    if (err != cudaSuccess) {                                      \
        cerr << "CUDA error: " << cudaGetErrorString(err)          \
             << " at line " << __LINE__ << endl;                   \
        exit(1);                                                   \
    }                                                             \
} while (0)

__global__ void multiplyKernel(
    const double* A,
    const double* B,
    double* C,
    int N)
{
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < N && col < N) {
        double sum = 0.0;

        for (int k = 0; k < N; k++) {
            sum += A[row * N + k] * B[k * N + col];
        }

        C[row * N + col] = sum;
    }
}

vector<double> readMatrix(const string& filename, int& N) {
    ifstream file(filename);

    if (!file.is_open()) {
        cerr << "Ошибка открытия файла: " << filename << endl;
        exit(1);
    }

    file >> N;

    vector<double> matrix(N * N);

    for (int i = 0; i < N * N; i++) {
        file >> matrix[i];
    }

    return matrix;
}

void writeMatrix(const string& filename, const vector<double>& matrix, int N) {
    ofstream file(filename);

    if (!file.is_open()) {
        cerr << "Ошибка записи в файл: " << filename << endl;
        exit(1);
    }

    file << N << endl;

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            file << matrix[i * N + j] << " ";
        }
        file << endl;
    }
}

float runCudaMultiply(
    const vector<double>& A,
    const vector<double>& B,
    vector<double>& C,
    int N,
    int blockX,
    int blockY)
{
    size_t bytes = static_cast<size_t>(N) * N * sizeof(double);

    double* d_A = nullptr;
    double* d_B = nullptr;
    double* d_C = nullptr;

    CUDA_CHECK(cudaMalloc(&d_A, bytes));
    CUDA_CHECK(cudaMalloc(&d_B, bytes));
    CUDA_CHECK(cudaMalloc(&d_C, bytes));

    CUDA_CHECK(cudaMemcpy(d_A, A.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_B, B.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemset(d_C, 0, bytes));

    dim3 block(blockX, blockY);
    dim3 grid(
        (N + block.x - 1) / block.x,
        (N + block.y - 1) / block.y
    );

    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    CUDA_CHECK(cudaEventRecord(start));

    multiplyKernel<<<grid, block>>>(d_A, d_B, d_C, N);

    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));

    float milliseconds = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&milliseconds, start, stop));

    CUDA_CHECK(cudaMemcpy(C.data(), d_C, bytes, cudaMemcpyDeviceToHost));

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));

    CUDA_CHECK(cudaFree(d_A));
    CUDA_CHECK(cudaFree(d_B));
    CUDA_CHECK(cudaFree(d_C));

    return milliseconds;
}

int main() {
    int deviceCount = 0;
    CUDA_CHECK(cudaGetDeviceCount(&deviceCount));

    cout << "CUDA devices found: " << deviceCount << endl;

    if (deviceCount == 0) {
        cerr << "CUDA device not found!" << endl;
        return 1;
    }

    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    cout << "GPU: " << prop.name << endl;

    CUDA_CHECK(cudaSetDevice(0));

    vector<int> sizes = {200, 400, 800, 1200, 1600, 2000};

    vector<pair<int, int>> blockConfigs = {
        {8, 8},
        {16, 16},
        {32, 8},
        {8, 32},
        {32, 16}
    };

    ofstream results("results_cuda.csv");

    if (!results.is_open()) {
        cerr << "Ошибка создания файла results_cuda.csv" << endl;
        return 1;
    }

    results << "N,BlockX,BlockY,GridX,GridY,KernelTimeMs\n";

    for (int N : sizes) {
        cout << "\n=== SIZE " << N << " ===" << endl;

        string cmd = "generate.exe " + to_string(N) + " inputA.txt inputB.txt";
        system(cmd.c_str());

        int N1, N2;

        vector<double> A = readMatrix("inputA.txt", N1);
        vector<double> B = readMatrix("inputB.txt", N2);

        if (N1 != N2) {
            cerr << "Ошибка: размеры матриц не совпадают!" << endl;
            return 1;
        }

        vector<double> C(static_cast<size_t>(N) * N, 0.0);

        for (auto config : blockConfigs) {
            int blockX = config.first;
            int blockY = config.second;

            int gridX = (N + blockX - 1) / blockX;
            int gridY = (N + blockY - 1) / blockY;

            float timeMs = runCudaMultiply(A, B, C, N, blockX, blockY);

            cout << "Block: " << blockX << "x" << blockY
                 << " | Grid: " << gridX << "x" << gridY
                 << " | Time: " << timeMs << " ms" << endl;

            results << N << ","
                    << blockX << ","
                    << blockY << ","
                    << gridX << ","
                    << gridY << ","
                    << fixed << setprecision(4) << timeMs << "\n";

            if (N == 200 && blockX == 16 && blockY == 16) {
                writeMatrix("result.txt", C, N);
            }
        }
    }

    results.close();

    cout << "\nALL TESTS DONE. Results saved to results_cuda.csv" << endl;
    cout << "Verification files saved: inputA.txt, inputB.txt, result.txt" << endl;

    return 0;
}