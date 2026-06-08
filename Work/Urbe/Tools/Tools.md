<style>
r { color: red }
o { color: Orange }
g { color: Green }
lg { color: lightgreen }
b { color: Blue }
lb { color: lightblue }

- To create tables:
  
  https://www.tablesgenerator.com/markdown_tables

> [!NOTE]  
> Highlights information that users should take into account, even when skimming.

> [!TIP]
> Optional information to help a user be more successful.

> [!IMPORTANT]
> Crucial information necessary for users to succeed.

> [!WARNING]  
> Critical content demanding immediate user attention due to potential risks.

> [!CAUTION]
> Negative potential consequences of an action.

> [!IDEA]
> XXXXX
</style>

### 1. Cloudflare

  - How to set up

  -  Cloudflare
     
     Con el cliente vas a empezar a tener acceso a todo lo nuevo que estamos desplegando con buenas prácticas, vas a poder llegar a 
     pgAdmin, etc

     Te logueás con SSO

     https://urbetrack.cloudflareaccess.com/#/Launcher

### 2. FinnegansGo

  - FIN.1981!Rac

### 3. Bitwarden

  - BIT.1891!!@kp

### 4. Portal de Urbetrack

  - lucas.liberatori@urbetrack.com
  - uRBe.2433!!Rac

### 5. Deploy SQL urbetrack local

PS C:\GitRepo\Utils\src\SqlScriptManager\bin\Debug\net6.0> 

setx SCRIPT_MANAGER_PATH "C:\GitRepo\Utils\src\SqlScriptManager\bin\Debug\net6.0\SqlScriptManager.exe"
setx SCRIPT_MANAGER_CONNSTRING "Driver={SQL Server};Server=172.23.208.1;Database=urbetrack;UID=urbetrack_web;PWD=Web!123*;Encrypt=True;Trust Server Certificate=True;"

.\SqlScriptManager.exe  -p 'C:\GitRepo\Urbetrack\Urbetrack\SQL Scripts\When-running-services' -cs "Driver={SQL Server};Server=172.23.208.1;Database=urbetrack;UID=urbetrack_web;PWD=Web!123*;Encrypt=True;Trust Server Certificate=True;" -b v20250513.3

![alt text](image.png)

En la tabla siguiente esta el log del deploy

SELECT * FROM [dbo].[soc.sys_sqlm_01_mov_scripts_log]

