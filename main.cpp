#include <iostream>
#include <vector>
#include <fstream>
#include <chrono>

using namespace std;

vector<vector<double>> readMatrix(const string& filename, int& N) {
    ifstream file(filename);
    if (!file.is_open()) {
        cerr << "Ошибка открытия файла: " << filename << endl;
        exit(1);
    }

    file >> N;

    vector<vector<double>> matrix(N, vector<double>(N));

    for (int i = 0; i < N; i++)
        for (int j = 0; j < N; j++)
            file >> matrix[i][j];

    file.close();
    return matrix;
}

void writeMatrix(const string& filename, const vector<vector<double>>& matrix) {
    ofstream file(filename);
    if (!file.is_open()) {
        cerr << "Ошибка записи в файл: " << filename << endl;
        exit(1);
    }

    int N = matrix.size();
    file << N << endl;

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++)
            file << matrix[i][j] << " ";
        file << endl;
    }

    file.close();
}

vector<vector<double>> multiplyMatrices(
    const vector<vector<double>>& A,
    const vector<vector<double>>& B,
    int N)
{
    vector<vector<double>> C(N, vector<double>(N, 0.0));

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            double sum = 0.0;
            for (int k = 0; k < N; k++) {
                sum += A[i][k] * B[k][j];
            }
            C[i][j] = sum;
        }
    }

    return C;
}

int main(int argc, char* argv[]) {

    if (argc != 4) {
        cout << "Использование: ./matrix inputA.txt inputB.txt output.txt" << endl;
        return 1;
    }

    string fileA = argv[1];
    string fileB = argv[2];
    string fileOut = argv[3];

    int N1, N2;

    vector<vector<double>> A = readMatrix(fileA, N1);
    vector<vector<double>> B = readMatrix(fileB, N2);

    if (N1 != N2) {
        cerr << "Ошибка: размеры матриц не совпадают!" << endl;
        return 1;
    }

    int N = N1;

    auto start = chrono::high_resolution_clock::now();

    vector<vector<double>> C = multiplyMatrices(A, B, N);

    auto end = chrono::high_resolution_clock::now();
    chrono::duration<double> duration = end - start;

    writeMatrix(fileOut, C);

    long long operations = static_cast<long long>(N) * N * N;

    cout << "Размер матрицы: " << N << " x " << N << endl;
    cout << "Объем задачи (N^3): " << operations << " операций" << endl;
    cout << "Время выполнения: " << duration.count() << " секунд" << endl;

    return 0;
}