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

> [!IMPORTANT]
> Para cerrar un ticket en Zoho se tiene que:
> Asignar + Validar + Transición + Cerrar

--------


### 1. DELETE data

Issue

Un viernes XX tuvieron un ticket de un cliente que se está por ir de la empresa y dejo colgadas las incidencias por lo cual se acumularon y llegaron a algún supuesto limite en SQL Server. Para solucionar este tema lo que hicieron fue meterse en PROD y cerrar incidencias para que las mismas no sean tomada por la query y que la misma termine.

Por lo que se ve esta acción de "cerrar incidencias" solo se realizó en una db por lo que durante la semana los arquitectos y R&D intentaron cerrar las incidencias también en la otra DB.


Detalle

El tema es así, los dispositivos GPS, por temas contractuales/auditoría, envian sus posiciones a 2 endpoints distintos. Es decir, se envía la misma posición a 2 servicios de URBE identicos (teoricamente) que terminan grabando en 2dbs distintas.
 
Una db es la que usan las empresas, la otra db es la que usa el gobierno de la ciudad para auditar.

Aparentemente tocaron a mano algo la semana pasada, que dejó alguna inconsistencia, entonces están haciendo la cochinada de nivelar a mano.

### INC000000400832 - degradación

• SQL de prod eMail - INC000000400832 - degradación
	
	Basicamente todas las noches hay un job del lado del proveedor que consolida la snapshot de la VM donde corre el SQL de Prod
	 
	La base de Prod pesa 4,5TB aprox
	 
	Entonces es un proceso relativamente largo. Creo que en condiciones normales dura 2hs aprox. El drama es que a veces se superpone con otros eventos nuestros y degrada la performance de la DB.
	 
	No se si te hicieron una intro de como funcionan los servicios acá, pero basicamente:
	 
	gateway --> ActiveMQ Queues <-- Dispatcher lee AMQ --> MSSQL
	 
	Entonces acá uno de los problemas mas grandes que hay y que todos se asustan es cuando se produce el "encolamiento". Llaman encolamiento a cuando las colas de mensajes de ActiveMQ empiezan a acumular mensajes, es decir, cuando los gateways guardan mas mensajes que los que los dispatchers leen, entonces crecen los topics de acuerdo al tráfico que hay en el momento.
	
	Hasta donde yo pude analizar, los dispatchers degradan su velocidad por los tiempos de respuesta del SQL, que cuando se superpone con las tareas de snapshot del proveedor, los tiempos de IO de disco se van al diablo. Además de que cada tanto sale alguna versión de las apps que tiran alguna query no indexada, entonces el SQL demora mucho.
	 
    Una de las cosas que deberíamos hacer para mitigar esto sería ver como podemos validar en el proceso de despliegue si hay queris nuevas que utilicen campos no indexados.

### GRAFANA QA

	• Add Monitoring
	
	Tenemos Grafana en QA (no se si ya tenés acceso, es por sso, sino se lo pedimos a Alan), que estoy viendo de poder visualizar el estado de las DBs MSSQL, pero eso sería a nivel engine. Podemos ver de sumar un Dashboard con paneles que nos avise de waiting tasks y otro tipo de queris que analicen la performance (sin matar al engine de sql), y en base a eso alertar.
	
	En Grafana existe un datasource de tipo mssql. Te permite hacer queries directo sobre la base, el tema es crear dashboards "estáticos" para que ningun bruto de los que nos rodean pueda tirar una query agresiva desde Grafana.
	
	https://grafana.com/docs/grafana/latest/datasources/mssql/
	
    Grafana Alloy es un agente que tiene todos los exporters de Prometheus, y además Loki y toda la bola del stack de Grafana (para lo que son VMs stand alone digo).

### Deploy Improvements

	• Improvements
	
	Pasa que salen versiones nuevas con queries nuevas sobre campos no indexados, entonces por un lado estaría bueno:
	
		a. Ver si podemos sumar algun stage en el pipeline para detectar este tipo de querys nuevas
        O hacer algun tipo de análisis para saber que cuando se ejecuten las queries en prod no vayan a matar al sql

### Migración gCABA

Aca se tiene que mgirar el SQL asi como esta
Primero migrar a SQL 2022 y despues en AWS








### #59630 Revision de Script en Red

Para la resolución de este ticket los pasos ejecutados fueron:

1. Ejecutar un SELECT del UPDATE a ejecutar
2. Guardar la Información en CSV y enviársela a Juan Pablo
3. Post validación de Juan P, se procedió a la ejecución del UPDATE
4. Se envió resultado del UPDATE como así también la información PRE y POST ejecución

Todo quedo correctamente ejecutado e informado.

