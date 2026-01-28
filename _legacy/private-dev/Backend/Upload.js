(async () => {
try {
  // Imports the Google Cloud client library
  const {Storage} = require('@google-cloud/storage');
  console.log('here 1');
  // Creates a client
  const storage = new Storage();
  console.log('here 2');
  /**
   * TODO(developer): Uncomment the following lines before running the sample.
   */
  const bucketName = 'tolling-network';
  const filename = './accounts.csv';
  console.log('here 3');
  // Uploads a local file to the bucket
  await storage.bucket(bucketName).upload(filename, {
    // Support for HTTP requests made with `Accept-Encoding: gzip`
    gzip: true,
    metadata: {
      // Enable long-lived HTTP caching headers
      // Use only if the contents of the file will never change
      // (If the contents will change, use cacheControl: 'no-cache')
      cacheControl: 'no-cache',
    },
  });

  console.log('here 4');

  console.log(`${filename} uploaded to ${bucketName}.`);
} catch (e) {
        console.log(e);
    }


})();
