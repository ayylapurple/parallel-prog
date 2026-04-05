#include <iostream>
#include <vector>
#include <fstream>
#include <chrono>
#include <string>

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
}

vector<vector<double>> multiplyMatrices(
    const vector<vector<double>>& A,
    const vector<vector<double>>& B,
    int N)
{
    vector<vector<double>> C(N, vector<double>(N, 0.0));

    for (int i = 0; i < N; i++) {
        for (int k = 0; k < N; k++) {
            double temp = A[i][k];
            for (int j = 0; j < N; j++) {
                C[i][j] += temp * B[k][j];
            }
        }
    }

    return C;
}

int main(int argc, char* argv[]) {

    vector<int> sizes = { 100, 200, 400, 800, 1200, 1600, 2000 };

    ofstream results("results_lab1.txt");
    results << "N Time(s)\n";

    for (int N : sizes) {

        cout << "=== SIZE " << N << " ===" << endl;

        string cmd = "generate.exe " + to_string(N) + " inputA.txt inputB.txt";
        system(cmd.c_str());

        int N1, N2;

        auto A = readMatrix("inputA.txt", N1);
        auto B = readMatrix("inputB.txt", N2);

        auto start = chrono::high_resolution_clock::now();

        auto C = multiplyMatrices(A, B, N);

        auto end = chrono::high_resolution_clock::now();
        chrono::duration<double> duration = end - start;

        cout << "Time: " << duration.count() << " sec" << endl;

        results << N << " " << duration.count() << "\n";
    }

    results.close();

    cout << "\n=== VERIFY TEST (N = 200) ===" << endl;

    int testN = 200;

    system("generate.exe 200 inputA.txt inputB.txt");

    int N1, N2;

    auto A = readMatrix("inputA.txt", N1);
    auto B = readMatrix("inputB.txt", N2);

    if (N1 != N2) {
        cerr << "Ошибка: размеры матриц не совпадают!" << endl;
        return 1;
    }

    auto start = chrono::high_resolution_clock::now();

    auto C = multiplyMatrices(A, B, N1);

    auto end = chrono::high_resolution_clock::now();
    chrono::duration<double> duration = end - start;

    writeMatrix("result.txt", C);

    cout << "Время: " << duration.count() << " сек" << endl;

    cout << "Матрицы сохранены: inputA.txt, inputB.txt, result.txt\n";

    return 0;
}
