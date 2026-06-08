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

### PostgreSQL 

	• Pidieron un motor de PostgreSQL hace un par de meses, y un pgAdmin para administrarlo 
	• Se instalo una VM con PostgreSQL como servicio, solo corre eso en esa VM y en otra VM se instaló pgAdmin
	• El equivalente ahora que estoy moviendo a KUBERNET sería, armar un Cluster de 3 nodos exclusivos para el engine de PostgreSQL, y en otro nodo de aplicaciones genericas correr pgAdmin/dbeaver/otras_tools
	• Lo mismo sucede con REDPANDA. De REDPANDA ya tengo los 3 nodos exclusivos para los brokers, y la consola web la tengo desplegada en otro nodo de apps genéricas.
	
	• URBE labura con dispositivos GPS que envían posiciones. A fines del año pasado salió un servicio nuevo, "barrido". 
    Ese servicio si bien la lógica que tiene es igual al resto de los servicios, es dedicado a los barrenderos de la ciudad, les dan unos relojes con GPS que envían la posición, entonces que pasa, para no seguir cargando la SQL, entiendo que los de ARQ pidieron la PostgreSQL. 


   ![alt text](image.png)

  