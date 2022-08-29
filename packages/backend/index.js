
import { ApolloServer } from 'apollo-server'
import mongoose from 'mongoose'
import env from 'dotenv'
import typeDefs from './src/schema.js'
import resolvers from './src/resolvers.js'
env.config()


const server = new ApolloServer({
    typeDefs,
    resolvers,
})


mongoose.connect(process.env.ATLAS_URI)
    .then(() => {
        console.log('🔌  MongoDB Connected')
        return server.listen({ port: process.env.MONGOOSE_PORT })
    })
    .then(({ url }) => {
        console.log(`🚀  Server ready at ${url}`)
    })
    .catch(err => {
        console.log(err)
    })




