#!/bin/bash -e

#
# This script builds plunger and puts it to the default location at ~/bin/plunger/*
# In order to use it everywhere, you should add that path to your PATH environment variable.
#
# Hints:
# - You can override that location by setting PLUNGER_HOME.
# - If the shortcuts like pls, pcat, pput and pcount are conflicting with other programs, you
#   can override the prefix used by setting PLUNGER_PREFIX (default is 'p')
#

PATH_SCRIPT=$(cd "$(dirname "$0")" && pwd)
PATH_BASE=${PATH_SCRIPT}/..
PLUNGER_NAME=plunger
PLUNGER_HOME=${PLUNGER_HOME-${HOME}/bin/${PLUNGER_NAME}}
PLUNGER_LIBS=${PLUNGER_HOME}/libs
PLUNGER_PREFIX=${PLUNGER_PREFIX-p}
if [ ! -d "${JAVA_HOME}" ]; then
	echo "JAVA_HOME is not set, exiting."
	exit 1
fi

function header() {
	echo -e "\n---------------- $1 ----------------"
}

#read -p "Installing ${PLUNGER_NAME} into ${PLUNGER_HOME} (Press enter to continue)"
echo "Installing ${PLUNGER_NAME} into ${PLUNGER_HOME}"


header "assemblying jar"
rm -rf ${PLUNGER_HOME}
mkdir -p ${PLUNGER_LIBS}
mvn -f ${PATH_BASE}/plunger/pom.xml clean install dependency:copy-dependencies -DincludeScope=compile -DoutputDirectory=${PLUNGER_LIBS} -Dgpg.skip=true
# Not required, inside the following dependencies as transient dependency
#cp ${PATH_BASE}/plunger/target/plunger-*.jar ${PLUNGER_LIBS}/plunger.jar

mvn -f ${PATH_BASE}/plunger-rabbitmq/pom.xml clean install dependency:copy-dependencies -DincludeScope=compile -DoutputDirectory=${PLUNGER_LIBS} -Dgpg.skip=true
cp ${PATH_BASE}/plunger-rabbitmq/target/plunger-rabbitmq-*-SNAPSHOT.jar ${PLUNGER_LIBS}/plunger-rabbitmq.jar

mvn -f ${PATH_BASE}/plunger-hornetq/pom.xml clean install dependency:copy-dependencies -DincludeScope=compile -DoutputDirectory=${PLUNGER_LIBS} -Dgpg.skip=true
cp ${PATH_BASE}/plunger-hornetq/target/plunger-hornetq-*-SNAPSHOT.jar ${PLUNGER_LIBS}/plunger-hornetq.jar

mvn -f ${PATH_BASE}/plunger-activemq/pom.xml clean install dependency:copy-dependencies -DincludeScope=compile -DoutputDirectory=${PLUNGER_LIBS} -Dgpg.skip=true
cp ${PATH_BASE}/plunger-activemq/target/plunger-activemq-*-SNAPSHOT.jar ${PLUNGER_LIBS}/plunger-activemq.jar

# Workaround, will check assembly-plugin instead.
#rm ${PLUNGER_LIBS}/plunger-*-SNAPSHOT.jar

#rm -f ${PLUNGER_HOME}/assembly-plunger.jar
#cp target/plunger-*-jar-with-dependencies.jar $PLUNGER_HOME/assembly-plunger.jar



header "creating launch-scripts"

echo "#!/bin/bash
PATH_SCRIPT=\$(cd \"\$(dirname \"\$0\")\" && pwd)
JAVA_HOME=\${JAVA_HOME}
if [ -f \"\${PATH_SCRIPT}/plunger-environment.sh\" ]; then
	. \${PATH_SCRIPT}/plunger-environment.sh
fi
\${JAVA_HOME}/bin/java -cp \${PATH_SCRIPT}/libs/\* de.galan.plunger.application.Plunger \$*
" > ${PLUNGER_HOME}/${PLUNGER_NAME}

#echo "\${JAVA_HOME}/bin/java -cp .:jars/* de.galan.plunger.application.Plunger \$*" >> ${PLUNGER_HOME}/${PLUNGER_NAME}

#echo "#!/bin/bash" > ${PLUNGER_HOME}/${PLUNGER_NAME}
#echo "PATH_SCRIPT=\$(cd \"\$(dirname \"\$0\")\" && pwd)" >> ${PLUNGER_HOME}/${PLUNGER_NAME}
#echo "JAVA_HOME=\${JAVA_HOME-\${HOME}/bin/jdk7}" >> ${PLUNGER_HOME}/${PLUNGER_NAME}
#echo "if []; then fi . \${PATH_SCRIPT}/plunger-environment.sh" >> ${PLUNGER_HOME}/${PLUNGER_NAME}
#echo "\${JAVA_HOME}/bin/java -cp \${PATH_SCRIPT}/libs/\* de.galan.plunger.application.Plunger \$*" >> ${PLUNGER_HOME}/${PLUNGER_NAME}
##echo "\${JAVA_HOME}/bin/java -cp .:jars/* de.galan.plunger.application.Plunger \$*" >> ${PLUNGER_HOME}/${PLUNGER_NAME}

chmod +x ${PLUNGER_HOME}/${PLUNGER_NAME}

createScript() {
	SCRIPT_NAME=${PLUNGER_HOME}/${PLUNGER_PREFIX}$1
	echo "#!/bin/bash
PATH_SCRIPT=\$(cd \"\$(dirname \"\$0\")\" && pwd)
target=\$1; shift 1
\${PATH_SCRIPT}/plunger \$target -C $1 \$*
	" > ${SCRIPT_NAME}
	chmod +x ${SCRIPT_NAME}
}

createScript cat
createScript ls
createScript put
createScript count


header "finished"
echo "Installed ${PLUNGER_NAME} into ${PLUNGER_HOME}"

if ! [[ -f `which ${PLUNGER_NAME}` ]]; then
	echo "You should expand your \$PATH to include \"$PLUNGER_HOME\""
fi


