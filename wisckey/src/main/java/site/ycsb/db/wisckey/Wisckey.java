package site.ycsb.db.wisckey;

/**
 * Concrete wisckey bindings implementation.
 */
public class Wisckey {
  static {
    System.loadLibrary("wisckeyjni"); // Load native library
  }

  // Declare an instance native method sayHello() which receives no parameter and returns void
  protected native boolean init();
  protected native boolean close();
  protected native byte[] get(ReadOptions rdopts, byte[] key, int keylen);
  protected native boolean insert(byte[] key, int keylen, byte[] value, int vallen);
  protected native boolean update(byte[] key, int keylen, byte[] value, int vallen);
  protected native boolean delete(byte[] key, int keylen);

}
