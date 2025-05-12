
NVCC = nvcc

CFLAGS = -Xcompiler -fopenmp

SRC = A.cu
OUT = A
ALL: $(OUT)

all: $(OUT)

$(OUT): $(SRC)
	$(NVCC) $(CFLAGS) $< -o $@

clean:
	rm -f $(OUT)
