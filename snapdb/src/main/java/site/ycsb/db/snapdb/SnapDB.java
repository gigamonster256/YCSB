package site.ycsb.db.snapdb;

/**
 * Concrete snapdb bindings implementation.
 */
public class SnapDB {
  static {
    System.loadLibrary("snapdbjni"); // Load native library
  }

  // Declare an instance native method sayHello() which receives no parameter and returns void
  protected native boolean init();
  protected native boolean close();
  protected native byte[] get(ReadOptions rdopts, byte[] key, int keylen);
  protected native boolean insert(byte[] key, int keylen, byte[] value, int vallen);
  protected native boolean update(byte[] key, int keylen, byte[] value, int vallen);
  protected native boolean delete(byte[] key, int keylen);

}
