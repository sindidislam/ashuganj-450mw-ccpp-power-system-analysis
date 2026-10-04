function h=phase5b_sha256(path)
md=java.security.MessageDigest.getInstance('SHA-256');
md.update(java.nio.file.Files.readAllBytes(java.io.File(char(path)).toPath()));
h=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2)',1,[]));
end
