package pgsqlexceutor;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import javax.xml.bind.DatatypeConverter;

public class Config implements Serializable {
    
    public String host = "localhost";
    public String db = "postgres";
    public String user = "postgres";
    public String pass = "postgres";
    
    public static Config load() {
        
        try {
            MessageDigest md = MessageDigest.getInstance("md5");
            md.update(new File("").getCanonicalPath().getBytes());
            String name = DatatypeConverter.printHexBinary(md.digest());
            
            File file = new File(System.getProperty("java.io.tmpdir"), name);
            
            if (!file.exists())
                return new Config();
            
            try (ObjectInputStream in = new ObjectInputStream(
                    new BufferedInputStream(new FileInputStream(file)))) {
                Object obj = in.readObject();
                if (obj instanceof Config)
                    return (Config) obj;
            }
        } catch (Throwable e) {
            PgSqlExceutor.showException(e);
        }
        return new Config();
    }
    
    public void save() throws IOException, NoSuchAlgorithmException {
        
        MessageDigest md = MessageDigest.getInstance("md5");
        md.update(new File("").getCanonicalPath().getBytes());
        String name = DatatypeConverter.printHexBinary(md.digest());
        
        File file = new File(System.getProperty("java.io.tmpdir"), name);
        
        try (ObjectOutputStream out = new ObjectOutputStream(
                new BufferedOutputStream(new FileOutputStream(file)))) {
            out.writeObject(this);
        }
    }
    
}
