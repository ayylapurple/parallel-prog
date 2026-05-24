import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("results_cuda.csv")

df["Block"] = df["BlockX"].astype(str) + "x" + df["BlockY"].astype(str)

block_order = (
    df[["BlockX", "BlockY", "Block"]]
    .drop_duplicates()
    .sort_values(["BlockX", "BlockY"])
)

blocks = block_order["Block"].tolist()

plt.figure(figsize=(10, 6))

for n in sorted(df["N"].unique()):
    subset = df[df["N"] == n].copy()

    subset["Block"] = pd.Categorical(
        subset["Block"],
        categories=blocks,
        ordered=True
    )

    subset = subset.sort_values("Block")

    plt.plot(
        subset["Block"],
        subset["KernelTimeMs"],
        marker="o",
        label=f"{n}x{n}"
    )

plt.xlabel("Конфигурация блока")
plt.ylabel("Время выполнения ядра (мс)")
plt.title("Зависимость времени CUDA-умножения от конфигурации блока")

plt.grid(True)
plt.legend()
plt.tight_layout()

plt.savefig("cuda_time_vs_block.png", dpi=300)
plt.show()