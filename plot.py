import matplotlib.pyplot as plt

N = []
time = []

with open("results_lab1.txt") as f:
    next(f)
    for line in f:
        n, t = line.split()
        N.append(int(n))
        time.append(float(t) * 1000)

plt.figure(figsize=(10, 6))

plt.plot(N, time, marker='o')

plt.xlabel("Размер матрицы (N)")
plt.ylabel("Время (мс)")
plt.title("Зависимость времени умножения матриц от размера")

plt.grid()

plt.savefig("time_vs_N.png")
plt.show()