import app, { client } from "./app.js";

import { readFileSync, readdirSync, writeFileSync} from "fs"

// Create a schema that contains an image property.
async function createSchema () {
    const schemaConfig = {
        'class': 'Employee',
        'vectorizer': "img2vec-neural",
        'vectorIndexType': 'hnsw',
        'moduleConfig': {
            'img2vec-neural': {
                'imageFields': [
                    'image'
                ]
            }
        },
        'properties': [
            {
                'name': 'image',
                'dataType': ['blob']
            },
            {
                'name': 'text',
                'dataType': ['string']
            }
        ]
    }

    await client.schema
        .classCreator()
        .withClass(schemaConfig)
        .do();
}

async function deleteSchema () {

    await client.schema
        .classDeleter()
        .withClassName("Employee")
        .do();

}

async function trainAllLocalImages () {
    const imgs = readdirSync('./img')

    const promises = imgs.map((async (img) => {
        const b64 = Buffer.from(readFileSync(`./img/${img}`)).toString('base64')
        await client.data
        .creator()
        .withClassName('Employee')
        .withProperties({
            image: b64,
            text: img.split('.')[0].split('_').join(' ')
        })
        .do();
    }))

    await Promise.all(promises)
}


/*
After storing a few images, we can provide an image
as a query input. The database will use HNSW to quickly
find similar looking images.
*/

async function test () {
    const test = Buffer.from( readFileSync('./test.png') ).toString('base64');

    const resImage = await client.graphql.get()
        .withClassName('Employee')
        .withFields(['image'])
        .withNearImage({ image: test })
        .withLimit(1)
        .do();

    // Write result to filesystem
    const result = resImage.data.Get.Employee[0].image;
    writeFileSync('./result.jpg', result, 'base64');
}

async function handleErrorInCreateSchema() {
    try {
        await createSchema();
    } catch (error) {
        try {
            await deleteSchema();
            await createSchema();
        } catch (deleteError) {
            process.exit(1);
        }
    }
}

await handleErrorInCreateSchema();
await trainAllLocalImages()
// await test()

app.post('/train-vector', async (req, res) => {
    try {
        const { image } = req.body;
        const { text } = req.body;

        const result = await client.data
            .creator()
            .withClassName('Employee')
            .withProperties({
                image: image,
                text: text,
            })
            .do();

        res.json({ message: "OK" });
    } catch (error) {
        console.error('Error while processing the image:', error);
        res.status(500).json({ error: 'Error while processing the image' });
    }
});

app.post('/process-image', async (req, res) => {
    try {
        const { image } = req.body;

        //console.log(image)

        const processedImage = await client.graphql.get()
            .withClassName('Employee')
            .withFields(['image'])
            .withNearImage({ image: image })
            .withLimit(1)
            .do();

        const result = processedImage.data.Get.Employee[0].image;
        // writeFileSync('./result.jpg', result, 'base64');
        res.json({ processedImage: result });
    } catch (error) {
        console.error('Error while processing the image:', error);
        res.status(500).json({ error: 'Error while processing the image' });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Listening ${PORT}`);
});
