public class Matrix4x4 {

  static Matrix4x4 add(Matrix4x4 left, Matrix4x4 right) {
    Matrix4x4 res = new Matrix4x4(left);
    return res.add(right);
  }
  
  static Matrix4x4 sub(Matrix4x4 left, Matrix4x4 right) {
    Matrix4x4 res = new Matrix4x4(left);
    return res.sub(right);
  }
  
  static Matrix4x4 mult(Matrix4x4 left, float right) {
    Matrix4x4 res = new Matrix4x4(left);
    return res.mult(right);
  }
  
  static Quaternion mult(Matrix4x4 left, Quaternion right) {
    Matrix4x4 res = new Matrix4x4(left);
    return res.mult(right);
  }
  
  static Matrix4x4 mult(Matrix4x4 left, Matrix4x4 right) {
    Matrix4x4 res = new Matrix4x4(left);
    return res.mult(right);
  }

  float[][] data;                                   // row, column
  
  Matrix4x4() {
    data = new float[4][4];
    fill(0);
  }
  
  Matrix4x4(Matrix4x4 mat) {
    this();
    for (int row = 0; row < 4; row++)
        for (int col = 0; col < 4; col++)
            data[row][col] = mat.data[row][col];
  }

  Matrix4x4 add(Matrix4x4 mat) {
      for (int row = 0; row < 4; row++)
        for (int col = 0; col < 4; col++)
          data[row][col] += mat.data[row][col];
    return this;
  }
  
  Matrix4x4 sub(Matrix4x4 mat) {
    for (int row = 0; row < 4; row++)
        for (int col = 0; col < 4; col++)
            data[row][col] -= mat.data[row][col];

    return this;
  }
  
  Matrix4x4 mult(float val) {
    for (int row = 0; row < 4; row++)
        for (int col = 0; col < 4; col++)
            data[row][col] *= val;

    return this;      
  }
  
  Quaternion mult(Quaternion q) {
    Quaternion res = new Quaternion();

    res.w = (data[0][0] * q.w + data[0][1] * q.x + data[0][2] * q.y + data[0][3] * q.z);
    res.x = (data[1][0] * q.w + data[1][1] * q.x + data[1][2] * q.y + data[1][3] * q.z);
    res.y = (data[2][0] * q.w + data[2][1] * q.x + data[2][2] * q.y + data[2][3] * q.z);
    res.z = (data[3][0] * q.w + data[3][1] * q.x + data[3][2] * q.y + data[3][3] * q.z);

    return res;
  }
  
  Matrix4x4 mult(Matrix4x4 mat) {
    Matrix4x4 res = new Matrix4x4();
    for (int row = 0; row < 4; row++)
        for (int col = 0; col < 4; col++)
            res.data[row][col] =
                    data[row][0] * mat.data[0][col] +
                    data[row][1] * mat.data[1][col] +
                    data[row][2] * mat.data[2][col] +
                    data[row][3] * mat.data[3][col];

    return res;
  }

  float val(int row, int col) { return data[row][col]; }
  void setVal(int row, int col, float val) { data[row][col] = val; }
  void fill(float val) {
    for (int row = 0; row < 4; row++)
      for (int col = 0; col < 4; col++)
          data[row][col] = val;
  }
  
  void setToIdentity() {
    fill(0);
    data[0][0] = 1;
    data[1][1] = 1;
    data[2][2] = 1;
    data[3][3] = 1;
  }

  Matrix4x4 inverted() {
    Matrix4x4 res = new Matrix4x4();
    float det = matDet();
    if (det == 0) {
        res.setToIdentity();
        return res;
    }
    for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 4; col++) {
            if (((row + col) & 1) == 1)
                res.data[col][row] = -matMinor(row, col) / det;
            else
                res.data[col][row] = matMinor(row, col) / det;
        }
    }
    return res;
  }
  
  Matrix4x4 transposed() {
    Matrix4x4 res = new Matrix4x4();
    for (int row = 0; row < 4; row++)
        for (int col = 0; col < 4; col++)
            res.data[col][row] = data[row][col];
    return res;
  }

  float matDet() {
    float det = 0;
    det += data[0][0] * matMinor(0, 0);
    det -= data[0][1] * matMinor(0, 1);
    det += data[0][2] * matMinor(0, 2);
    det -= data[0][3] * matMinor(0, 3);
    return det;
  }
  
  float matMinor(final int row, final int col) {
    int[] map = {1, 2, 3, 0, 2, 3, 0, 1, 3, 0, 1, 2};  
    int rc0 = map[row * 3];
    int rc1 = map[row * 3 + 1];
    int rc2 = map[row * 3 + 2];
    int cc0 = map[col * 3];
    int cc1 = map[col * 3 + 1];
    int cc2 = map[col * 3 + 2];
    
    float res = 0;
    res += data[rc0][cc0] * data[rc1][cc1] * data[rc2][cc2];
    res -= data[rc0][cc0] * data[rc1][cc2] * data[rc2][cc1];
    res -= data[rc0][cc1] * data[rc1][cc0] * data[rc2][cc2];
    res += data[rc0][cc1] * data[rc1][cc2] * data[rc2][cc0];
    res += data[rc0][cc2] * data[rc1][cc0] * data[rc2][cc1];
    res -= data[rc0][cc2] * data[rc1][cc1] * data[rc2][cc0];
    return res;
  }
  
  public String toString() {
    return "[ " +
      data[0][0] + ", " + data[0][1] + ", " + data[0][2] + ", " + data[0][3] + ", " +
      data[1][0] + ", " + data[1][1] + ", " + data[1][2] + ", " + data[1][3] + ", " +
      data[2][0] + ", " + data[2][1] + ", " + data[2][2] + ", " + data[2][3] + ", " +
      data[3][0] + ", " + data[3][1] + ", " + data[3][2] + ", " + data[3][3] + " ]";
  }
}
