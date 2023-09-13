# TP final

1. Contexte : Je suis anti conformiste et j'ai dev une app custom, elle est vulnérable au SSTI. Je ne veux pas la fix donc pour la sécu vous voulez détecter les attaques.
2. Partage du folder avec le container vulnérable aux étudiants  
3. Rappel qu'ils doivent changer la configuration ossec.conf de l'agent s’ils n'ont pas up la stack via docker compose comme recommandé
4. `docker compose up -d --build --remove-orphans`
5. tout ce qu'ils ont besoin est dans le code source + la doc officielle qui est tres bien faites
6. Leur expliquer que c'est une app custom + on est anti conformiste donc on met pas les logs dans /var/log mais /app/app.log ils faut donc qu'ils edit la conf de leur agent :
 
ajout du localfile /app/app.log sur le client ossec.conf
```xml
<localfile>
	<log_format>syslog</log_format>
	<location>/app/app.log</location>
</localfile>
```
7. Nous n'avons aussi pas respecté la convention SYSLOG dans notre format de génération de logs, voir :  `%(asctime)s PYTHON_APP: %(levelname)s-%(message)s`. Il est donc nécessaire de faire un decoder comme dans le cours. 
```xml
<!--
Nous recommandons l'utilisation du **decoders test**
2023-09-11 10:04:43,045 PYTHON_APP: INFO-POSTED_DATAS : test
-->
<decoder name="PythonApp">
	<program_name>PYTHON_APP</program_name>
</decoder>

<decoder name="PythonApp">
	<parent>PythonApp</parent>
	<regex>(\w+)-(\w+) : (\.+)</regex>
	<order>type,action,datas</order>
</decoder>
```
6. On voit maintenant les alertes générées depuis dashboad que l'on peut filtrer, etc.. : `predecoder.program_name is python_app`
7. Reste a faire une alerte, plein de techniques possible même si aucune n'est incroyable. En vrai on utiliserait les logs d'un waf ou d'un tool comme [teler](https://github.com/kitabisa/teler#) par exemple
```xml
<group name="custom_rules_python_app,">
  <rule id="100010" level="0">
    <program_name>PYTHON_APP</program_name>
    <description>match python_app logs</description>
  </rule> 

  <rule id="100011" level="5">  
    <if_sid>100010</if_sid>
    <action>POSTED_DATAS</action>
    <description>match posted data</description>
    <group>local,pci_dss_10.2.5,</group>  
  </rule>   

  <rule id="100012" level="5">  
    <if_sid>100010</if_sid>
    <action>RETURNED_DATAS</action>
    <description>match retourned data</description>
    <group>local,</group>  
  </rule> 

  <rule id="100013" level="13">
    <if_sid>100011</if_sid>
    <field name="datas">\p+</field>
    <description>Probable SSTI: detection of special characters in data sent by a user</description>
    <group>local,vuls,</group>
    <mitre>
      <id>T1221</id>
    </mitre>    
  </rule>
</group>
```
8. Pour aller plus loin : soit faire le script d'[active response](https://documentation.wazuh.com/current/getting-started/use-cases/active-response.html) a l'attaque ou alors faire l'alerte sur un vrai waf/tool etc...
