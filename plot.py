import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("results_cuda.csv")

best = df.loc[df.groupby("N")["KernelTimeMs"].idxmin()]

plt.figure(figsize=(10, 6))

plt.plot(
    best["N"],
    best["KernelTimeMs"],
    marker="o"
)

plt.xlabel("Размер матрицы (N)")
plt.ylabel("Лучшее время выполнения ядра (мс)")
plt.title("Зависимость времени CUDA-умножения матриц от размера")

plt.grid(True)
plt.savefig("cuda_best_time_vs_size.png", dpi=300)
plt.show()

print(best[["N", "BlockX", "BlockY", "KernelTimeMs"]])