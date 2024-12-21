const express = require('express')
const app = express()
const port= process.env.PORT || 4000  

app.get('/', (req, res) => {
        res.send('Hello ibtisam, my love')
})

app.listen(port, ()  => {
        console.log(`Example app listening at http://localhost:${port}`)
})


// The server listens on the port defined by process.env.PORT or defaults to 4000 if not set.