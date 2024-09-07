#!/bin/bash

# Función para imprimir mensajes en tres idiomas
print_message() {
    echo "🇬🇧 $1"
    echo "🇪🇸 $2"
    echo "🇫🇷 $3"
    echo ""
}

# Función para manejar errores
handle_error() {
    print_message "❌ Error on line $1" "❌ Error en la línea $1" "❌ Erreur à la ligne $1"
    exit 1
}

# Activar el modo de salida en error
set -e

# Configurar el manejador de errores
trap 'handle_error $LINENO' ERR

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null
then
    print_message "Docker is not installed. Do you want to install it? (y/n)" "Docker no está instalado. ¿Quieres instalarlo? (s/n)" "Docker n'est pas installé. Voulez-vous l'installer ? (o/n)"
    read answer
    case ${answer:0:1} in
        y|Y|s|S|o|O )
            print_message "Installing Docker..." "Instalando Docker..." "Installation de Docker..."
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                sudo apt-get update
                sudo apt-get install -y docker.io
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                brew install --cask docker
            else
                print_message "Please install Docker manually and run this script again." "Por favor, instala Docker manualmente y ejecuta este script de nuevo." "Veuillez installer Docker manuellement et exécuter à nouveau ce script."
                exit 1
            fi
            ;;
        * )
            print_message "Docker installation skipped. Note that Supabase requires Docker." "Instalación de Docker omitida. Ten en cuenta que Supabase requiere Docker." "Installation de Docker ignorée. Notez que Supabase nécessite Docker."
            ;;
    esac
fi

# Nombre del proyecto
print_message "🚀 Please enter your project name:" "🚀 Por favor, ingresa el nombre de tu proyecto:" "🚀 Veuillez entrer le nom de votre projet :"
read PROJECT_NAME

# Comprobar si el directorio ya existe
while [ -d "$PROJECT_NAME" ]; do
    print_message "⚠️ The directory '$PROJECT_NAME' already exists. What would you like to do?" "⚠️ El directorio '$PROJECT_NAME' ya existe. ¿Qué te gustaría hacer?" "⚠️ Le répertoire '$PROJECT_NAME' existe déjà. Que voulez-vous faire ?"
    print_message "1. Choose a different name" "1. Elegir un nombre diferente" "1. Choisir un nom différent"
    print_message "2. Overwrite the existing directory" "2. Sobrescribir el directorio existente" "2. Écraser le répertoire existant"
    print_message "3. Exit" "3. Salir" "3. Quitter"
    read -p "Enter your choice (1/2/3): " choice

    case $choice in
        1)
            print_message "Please enter a new project name:" "Por favor, ingresa un nuevo nombre para el proyecto:" "Veuillez entrer un nouveau nom de projet :"
            read PROJECT_NAME
            ;;
        2)
            print_message "⚠️ The existing directory will be overwritten. Are you sure? (y/n)" "⚠️ El directorio existente será sobrescrito. ¿Estás seguro? (s/n)" "⚠️ Le répertoire existant sera écrasé. Êtes-vous sûr ? (o/n)"
            read confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                rm -rf "$PROJECT_NAME"
                break
            fi
            ;;
        3)
            print_message "Exiting script." "Saliendo del script." "Sortie du script."
            exit 0
            ;;
        *)
            print_message "Invalid choice. Please try again." "Opción inválida. Por favor, intenta de nuevo." "Choix invalide. Veuillez réessayer."
            ;;
    esac
done

# Clonar el template de Mantine Remix
print_message "🎵 Cloning Mantine Remix template..." "🎵 Clonando el template de Mantine Remix..." "🎵 Clonage du modèle Mantine Remix..."
git clone https://github.com/mantinedev/remix-template.git $PROJECT_NAME || { print_message "❌ Error cloning Mantine Remix template" "❌ Error al clonar el template de Mantine Remix" "❌ Erreur lors du clonage du modèle Mantine Remix"; exit 1; }

# Entrar al directorio del proyecto
print_message "📂 Entering project directory..." "📂 Entrando al directorio del proyecto..." "📂 Entrée dans le répertoire du projet..."
cd $PROJECT_NAME || { print_message "❌ Error entering project directory" "❌ Error al entrar al directorio del proyecto" "❌ Erreur lors de l'entrée dans le répertoire du projet"; exit 1; }

# Eliminar el directorio .git para iniciar un nuevo repositorio
rm -rf .git

# Instalar dependencias
print_message "📦 Installing dependencies..." "📦 Instalando dependencias..." "📦 Installation des dépendances..."
npm install @mantine/core@6.0.21 @mantine/hooks@6.0.21 @mantine/remix@6.0.21 @emotion/server@11.11.0 @emotion/react@11.11.1 @supabase/supabase-js @tabler/icons-react || { print_message "❌ Error installing dependencies" "❌ Error al instalar las dependencias" "❌ Erreur lors de l'installation des dépendances"; exit 1; }

# Instalar Supabase
print_message "📦 Installing Supabase..." "📦 Instalando Supabase..." "📦 Installation de Supabase..."
npm install @supabase/supabase-js || { print_message "❌ Error installing Supabase" "❌ Error al instalar Supabase" "❌ Erreur lors de l'installation de Supabase"; exit 1; }

# Crear un archivo de configuración de Supabase
print_message "⚙️ Creating Supabase configuration file..." "⚙️ Creando archivo de configuración de Supabase..." "⚙️ Création du fichier de configuration Supabase..."
mkdir -p app/utils
cat << EOF > app/utils/supabase.server.ts
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
EOF

# Inicializar Supabase
print_message "🗃️ Initializing Supabase..." "🗃️ Inicializando Supabase..." "🗃️ Initialisation de Supabase..."
npx supabase init || { print_message "❌ Error initializing Supabase" "❌ Error al inicializar Supabase" "❌ Erreur lors de l'initialisation de Supabase"; exit 1; }

# Iniciar Supabase
print_message "🚀 Starting Supabase..." "🚀 Iniciando Supabase..." "🚀 Démarrage de Supabase..."
npx supabase start || { print_message "❌ Error starting Supabase" "❌ Error al iniciar Supabase" "❌ Erreur lors du démarrage de Supabase"; exit 1; }

# Obtener las claves de Supabase
print_message "🔑 Getting Supabase keys..." "🔑 Obteniendo las claves de Supabase..." "🔑 Obtention des clés Supabase..."
SUPABASE_URL=$(npx supabase status | grep 'API URL' | awk '{print $3}')
SUPABASE_ANON_KEY=$(npx supabase status | grep 'anon key' | awk '{print $3}')

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    print_message "❌ Error: Could not get Supabase keys" "❌ Error: No se pudieron obtener las claves de Supabase" "❌ Erreur : Impossible d'obtenir les clés Supabase"
    exit 1
fi

# Crear archivo .env para las variables de entorno de Supabase
print_message "📝 Creating .env file..." "📝 Creando archivo .env..." "📝 Création du fichier .env..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

# Crear tabla y insertar datos en Supabase
print_message "🗃️ Creating table and inserting data in Supabase..." "🗃️ Creando tabla e insertando datos en Supabase..." "🗃️ Création de la table et insertion de données dans Supabase..."
npx supabase db reset || { print_message "❌ Error resetting Supabase database" "❌ Error al resetear la base de datos de Supabase" "❌ Erreur lors de la réinitialisation de la base de données Supabase"; exit 1; }
npx supabase migration new create_tasks_table || { print_message "❌ Error creating migration" "❌ Error al crear la migración" "❌ Erreur lors de la création de la migration"; exit 1; }
cat << EOF > supabase/migrations/$(ls supabase/migrations | tail -n 1)
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  completed BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO tasks (title) VALUES
  ('Learn Remix'),
  ('Master Supabase'),
  ('Create an amazing app');
EOF

npx supabase db reset || { print_message "❌ Error applying migration" "❌ Error al aplicar la migración" "❌ Erreur lors de l'application de la migration"; exit 1; }

# Modificar el archivo root.tsx para incluir Mantine y estilos globales
print_message "🎨 Configuring Mantine and global styles..." "🎨 Configurando Mantine y estilos globales..." "🎨 Configuration de Mantine et des styles globaux..."
cat << EOF > app/root.tsx
import { useState } from 'react';
import type { LinksFunction, V2_MetaFunction } from "@remix-run/node";
import {
  Links,
  LiveReload,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
} from "@remix-run/react";
import { MantineProvider, createEmotionCache } from '@mantine/core';
import { StylesPlaceholder } from '@mantine/remix';

export const meta: V2_MetaFunction = () => [{
  charset: "utf-8",
  title: "New Remix App",
  viewport: "width=device-width,initial-scale=1",
}];

export const links: LinksFunction = () => [];

const emotionCache = createEmotionCache({ key: 'mantine' });

export default function App() {
  const [colorScheme] = useState('light');

  return (
    <html lang="en">
      <head>
        <Meta />
        <Links />
        <StylesPlaceholder />
      </head>
      <body>
        <MantineProvider emotionCache={emotionCache} withGlobalStyles withNormalizeCSS theme={{
          colorScheme,
          primaryColor: 'blue',
        }}>
          <Outlet />
        </MantineProvider>
        <ScrollRestoration />
        <Scripts />
        <LiveReload />
      </body>
    </html>
  );
}
EOF

# Crear el archivo entry.server.tsx
print_message "🖥️ Creating entry.server.tsx file..." "🖥️ Creando archivo entry.server.tsx..." "🖥️ Création du fichier entry.server.tsx..."
cat << EOF > app/entry.server.tsx
import { renderToString } from 'react-dom/server';
import { RemixServer } from '@remix-run/react';
import type { EntryContext } from '@remix-run/node';
import { injectStyles, createStylesServer } from '@mantine/remix';
import { createEmotionCache } from '@mantine/core';

const server = createStylesServer(createEmotionCache({ key: 'mantine' }));

export default function handleRequest(
  request: Request,
  responseStatusCode: number,
  responseHeaders: Headers,
  remixContext: EntryContext
) {
  let markup = renderToString(
    <RemixServer context={remixContext} url={request.url} />
  );
  responseHeaders.set('Content-Type', 'text/html');

  return new Response(\`<!DOCTYPE html>\${injectStyles(markup, server)}\`, {
    status: responseStatusCode,
    headers: responseHeaders,
  });
}
EOF

# Modificar el archivo routes/_index.tsx para incluir un componente de Mantine y renderizar datos
print_message "📝 Creating home page..." "📝 Creando página de inicio..." "📝 Création de la page d'accueil..."
cat << EOF > app/routes/_index.tsx
import { json, LoaderFunction } from "@remix-run/node";
import { useLoaderData } from "@remix-run/react";
import { Button, Container, Text, Title, List, Checkbox, Stack, Group, Box, keyframes, Accordion, Code } from '@mantine/core';
import { IconRocket, IconBrain, IconCode, IconFolder, IconFile } from '@tabler/icons-react';
import { supabase } from "~/utils/supabase.server";
import packageJson from '../../package.json';

type Task = {
  id: number;
  title: string;
  completed: boolean;
};

type Dependency = {
  name: string;
  version: string;
};

export const loader: LoaderFunction = async () => {
  const { data: tasks, error } = await supabase.from('tasks').select('*');
  if (error) throw new Error('Error loading tasks');

  const allDependencies = { ...packageJson.dependencies, ...packageJson.devDependencies };
  const relevantDependencies: Dependency[] = [
    '@mantine/core',
    '@mantine/hooks',
    '@mantine/remix',
    '@supabase/supabase-js',
    '@tabler/icons-react',
    '@remix-run/react',
    '@remix-run/node',
    'react',
    'react-dom'
  ].map(name => ({ name, version: allDependencies[name] }));

  return json({ tasks, dependencies: relevantDependencies });
};

const bounce = keyframes({
  '0%, 100%': { transform: 'translateY(0)' },
  '50%': { transform: 'translateY(-20px)' },
});

const fadeIn = keyframes({
  from: { opacity: 0, transform: 'translateY(20px)' },
  to: { opacity: 1, transform: 'translateY(0)' },
});

const DirectoryStructure = () => (
  <Accordion>
    <Accordion.Item value="structure">
      <Accordion.Control icon={<IconFolder size={20} />}>
        Estructura de directorios
      </Accordion.Control>
      <Accordion.Panel>
        <Code block>
          {\`
app/
├── entry.client.tsx
├── entry.server.tsx
├── root.tsx
├── routes/
│   └── _index.tsx
└── utils/
    └── supabase.server.ts
public/
supabase/
├── migrations/
│   └── ...
└── ...
          \`.trim()}
        </Code>
      </Accordion.Panel>
    </Accordion.Item>
  </Accordion>
);

const DependenciesList = ({ dependencies, title }: { dependencies: Dependency[], title: string }) => (
  <Accordion>
    <Accordion.Item value={title}>
      <Accordion.Control icon={<IconFile size={20} />}>
        {title}
      </Accordion.Control>
      <Accordion.Panel>
        <List>
          {dependencies.map((dep) => (
            <List.Item key={dep.name}>
              {dep.name}: {dep.version}
            </List.Item>
          ))}
        </List>
      </Accordion.Panel>
    </Accordion.Item>
  </Accordion>
);

export default function Index() {
  const { tasks, dependencies } = useLoaderData<{ tasks: Task[], dependencies: Dependency[] }>();

  const openDocs = () => {
    window.open('https://remix.run/docs', '_blank');
    window.open('https://supabase.com/docs', '_blank');
    window.open('https://mantine.dev/getting-started/', '_blank');
  };

  return (
    <Container size="md" mt="xl">
      <Stack spacing="xl" align="center">
        <Box sx={{ animation: \`\${bounce} 2s ease-in-out infinite\` }}>
          <Title order={1} align="center" sx={(theme) => ({
            background: theme.fn.linearGradient(45, theme.colors.blue[5], theme.colors.cyan[5]),
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
          })}>
            🚀 Welcome to your Remix + Supabase + Mantine app!
          </Title>
        </Box>
        <Text size="lg" align="center" sx={{ animation: \`\${fadeIn} 1s ease-out\` }}>
          Here's a list of tasks to get you started:
        </Text>
        <List spacing="md" size="lg" center icon={
          <Box sx={{ animation: \`\${bounce} 1s ease-in-out infinite\` }}>
            🌟
          </Box>
        }>
          {tasks.map((task, index) => (
            <List.Item key={task.id} sx={{ animation: \`\${fadeIn} 1s ease-out \${index * 0.2}s\` }}>
              <Checkbox 
                label={task.title} 
                checked={task.completed} 
                readOnly 
                icon={task.completed ? IconRocket : undefined}
              />
            </List.Item>
          ))}
        </List>
        <Group position="center" sx={{ animation: \`\${fadeIn} 1s ease-out 0.6s\` }}>
          <Button 
            onClick={openDocs} 
            size="lg" 
            leftIcon={<IconBrain size={20} />}
            rightIcon={<IconCode size={20} />}
            gradient={{ from: 'indigo', to: 'cyan' }}
            variant="gradient"
          >
            Start developing! 🚀
          </Button>
        </Group>
        <Box sx={{ width: '100%', animation: \`\${fadeIn} 1s ease-out 0.8s\` }}>
          <Title order={2} align="center" mb="md">Project Information</Title>
          <DirectoryStructure />
          <DependenciesList dependencies={dependencies} title="Project Dependencies" />
        </Box>
      </Stack>
    </Container>
  );
}
EOF

# Modificar el archivo package.json para incluir los scripts necesarios
print_message "📝 Updating package.json..." "📝 Actualizando package.json..." "📝 Mise à jour de package.json..."
npm pkg set scripts.dev="remix dev"
npm pkg set scripts.build="remix build"
npm pkg set scripts.start="remix-serve build"

print_message "✅ Setup completed. Starting development server..." "✅ Configuración completada. Iniciando el servidor de desarrollo..." "✅ Configuration terminée. Démarrage du serveur de développement..."

# Función para abrir el navegador
open_browser() {
    local url="http://localhost:3000"
    print_message "🌐 Opening $url in the browser..." "🌐 Abriendo $url en el navegador..." "🌐 Ouverture de $url dans le navigateur..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$url"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open "$url"
    elif [[ "$OSTYPE" == "msys" ]]; then
        start "$url"
    else
        print_message "❌ Could not open browser automatically. Please open $url manually" "❌ No se pudo abrir el navegador automáticamente. Por favor, abre manualmente $url" "❌ Impossible d'ouvrir le navigateur automatiquement. Veuillez ouvrir $url manuellement"
    fi
}

# Después de modificar los archivos y antes de iniciar el servidor de desarrollo

# Limpiar caché y reinstalar dependencias
print_message "🧹 Cleaning npm cache and reinstalling dependencies..." "🧹 Limpiando caché de npm y reinstalando dependencias..." "🧹 Nettoyage du cache npm et réinstallation des dépendances..."
npm cache clean --force
rm -rf node_modules
npm install

# Construir el proyecto
print_message "🏗️ Building the project..." "🏗️ Construyendo el proyecto..." "🏗️ Construction du projet..."
npm run build || { print_message "❌ Error building the project" "❌ Error al construir el proyecto" "❌ Erreur lors de la construction du projet"; exit 1; }

# Suprimir la advertencia de punycode
export NODE_OPTIONS="--no-deprecation"

# Iniciar el servidor de desarrollo
print_message "🚀 Starting development server..." "🚀 Iniciando servidor de desarrollo..." "🚀 Démarrage du serveur de développement..."
npm run dev &

# Esperar a que el servidor esté listo
while ! nc -z localhost 3000; do   
  sleep 1
done

# Abrir el navegador
open_browser

# Eliminar todas las referencias a Tailwind
print_message "🧹 Removing all Tailwind references..." "🧹 Eliminando todas las referencias a Tailwind..." "🧹 Suppression de toutes les références à Tailwind..."
rm -f tailwind.config.js tailwind.config.ts postcss.config.js app/tailwind.css
sed -i '' '/tailwind/d' app/root.tsx
sed -i '' '/tailwind/d' package.json
npm uninstall tailwindcss postcss autoprefixer

# Esperar a que el proceso npm termine
wait

print_message "✅ Tailwind has been completely removed from the project." "✅ Tailwind ha sido completamente eliminado del proyecto." "✅ Tailwind a été complètement supprimé du projet."

# Crear un directorio para el proyecto
print_message "📁 Creating project directory..." "📁 Creando directorio del proyecto..." "📁 Création du répertoire du projet..."
mkdir -p $PROJECT_NAME

# Mover los archivos al nuevo directorio
print_message "📁 Moving files to project directory..." "📁 Moviendo archivos al directorio del proyecto..." "📁 Déplacement des fichiers vers le répertoire du projet..."
mv README.md $PROJECT_NAME
mv setup-remix-supabase-mantine.sh $PROJECT_NAME

# Inicializar un nuevo repositorio Git
print_message "🌱 Initializing Git repository..." "🌱 Inicializando repositorio Git..." "🌱 Initialisation du dépôt Git..."
cd $PROJECT_NAME
git init

# Crear un archivo .gitignore
print_message "📝 Creating .gitignore file..." "📝 Creando archivo .gitignore..." "📝 Création du fichier .gitignore..."
cat << EOF > .gitignore
# Ignorar archivos generados
/node_modules
/.cache
/build
/public/build
EOF

# Añadir los archivos al staging area de Git
print_message "📝 Adding files to Git staging area..." "📝 Añadiendo archivos al área de staging de Git..." "📝 Ajout des fichiers à la zone de staging Git..."
git add .

# Hacer el commit inicial
print_message "📝 Making initial commit..." "📝 Haciendo commit inicial..." "📝 Faire le commit initial..."
git commit -m "Initial commit"

# Crear un archivo README.md
print_message "📝 Creating README.md file..." "📝 Creando archivo README.md..." "📝 Création du fichier README.md..."
cat << EOF > README.md
# Welcome to the Remix + Supabase + Mantine project!

This project is a template for creating a full-stack application using Remix, Supabase, and Mantine. It provides a basic setup for a Remix project with Supabase as the backend and Mantine as the UI library.

## Features

- Remix: A React framework for building fast, modern web applications.
- Supabase: An open-source Firebase alternative that provides a Postgres database, authentication, and real-time subscriptions.
- Mantine: A React component library with a focus on usability, accessibility, and developer experience.

## Getting Started

1. Clone this repository:
   \`\`\`
   git clone https://github.com/your-username/remix-supabase-mantine.git
   \`\`\`
2. Install dependencies:
   \`\`\`
   cd remix-supabase-mantine
   npm install
   \`\`\`
3. Start the development server:
   \`\`\`
   npm run dev
   \`\`\`
4. Open your browser and navigate to [http://localhost:3000](http://localhost:3000) to see the application.

## System Requirements

- Node.js (v14 or later)
- npm (v6 or later)

## Documentation

- [Remix](https://remix.run/docs/en/main)
- [Supabase](https://supabase.com/docs)
- [Mantine](https://mantine.dev/getting-started/)

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
EOF