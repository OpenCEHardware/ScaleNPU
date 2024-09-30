import numpy as np

# Define matrices
A = np.array([  [  77,  -36,   54,  -72 ]])

B = np.array([    [  85,   37,   -3, -115, -110, -98, 95, -14],
                  [  98,   10,   13,  -15,   -43, 69, 68, 37],
                  [ -35, -128,  -26,   53,   -20, -5, 127, -81],
                  [ -58,  -47,   43,  -57,   -53, 94, 34, 109]])


# Matrix multiplication using NumPy's dot function
result = np.dot(A, B)


# vector = np.array([-128,  -91,   10,  -89,   10,   10,  127,   10])

# Add the vector to the result
# sum_result = result + vector

print("Matrix multiplication result:")
print(result)


# print("Sum with vector:")
# print(sum_result)