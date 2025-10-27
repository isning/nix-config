# 3. Generate the private key for PIV
# NOTE: Windows Bitlocker supports RSA2048
openssl genrsa -out ecc-piv.key 2048
# 4. Generate the certificate signing request (CSR) for the server certificate
# using the private key and the configuration file ecc-piv-csr.conf
openssl req -SHA512 -new -key ecc-piv.key -out ecc-piv.csr -config ecc-piv-csr.conf
# 5. Sign the server certificate with the Root CA's certificate and private key
openssl x509 -SHA512 -req -in ecc-piv.csr -CA ecc-ca.crt -CAkey ecc-ca.key \
  -CAcreateserial -out ecc-piv.crt -days 365 \
  -extensions v3_ext -extfile ecc-piv-csr.conf

# 6. Display the information of the certificates
openssl x509 -noout -text -in ecc-piv.crt
#openssl x509 -noout -text -in ecc-server.crt

# Create cert by yubico-piv-tool
#yubico-piv-tool -r canokey -a generate -s 9a -A ECCP256 -o ecc-piv.pub
#yubico-piv-tool -r canokey -a verify-pin -a request-certificate -s 9a -S '/CN=ISNing PIV 1/OU=Personal PIV/O=ISNing/' -i ecc-piv.pub -o ecc-piv.csr

# Import key and certificate
yubico-piv-tool -r canokey -a import-key -s 9a -i ecc-piv.key
yubico-piv-tool -r canokey -a import-certificate -s 9a -i ecc-piv.crt

