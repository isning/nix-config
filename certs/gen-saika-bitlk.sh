# 3. Generate the private key for saika-bitlk
# NOTE: Windows Bitlocker supports RSA2048
openssl genrsa -out ecc-saika-bitlk.key 2048
# 4. Generate the certificate signing request (CSR) for the server certificate
# using the private key and the configuration file ecc-saika-bitlk-csr.conf
openssl req -SHA512 -new -key ecc-saika-bitlk.key -out ecc-saika-bitlk.csr -config ecc-saika-bitlk-csr.conf
# 5. Sign the server certificate with the Root CA's certificate and private key
openssl x509 -SHA512 -req -in ecc-saika-bitlk.csr -CA ecc-ca.crt -CAkey ecc-ca.key \
  -CAcreateserial -out ecc-saika-bitlk.crt -days 365 \
  -extensions v3_ext -extfile ecc-saika-bitlk-csr.conf

# 6. Display the information of the certificates
openssl x509 -noout -text -in ecc-saika-bitlk.crt
