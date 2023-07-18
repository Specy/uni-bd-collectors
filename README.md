# uni-bd-collectors
Project submission for "Laboratorio base di dati", the final document can be viewed in `submission/Progetto.pdf` (in italian, source code is in `submission/Progetto.md`). 

## Run the project
To run the project you must have `node.js` and npm installed. An existing mysql is assumed to exist with those credentials:
```ts
export const DEFAULT_CONNECTION = {
    host: "localhost",
    port: 3306,
    user: "root",
    password: "root",
} satisfies ConnectionOptions
```
it can be edited in `GUI/electron/src/db/db.ts`. The project will then create the database, tables, procedures, triggers and some mock data. 

To run the project, go to the `GUI` folder and run 
```bash
npm run install-and-run
```
which will install all dependencies, compile the typescript and sveltekit code and run the electron app.