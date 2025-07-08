export const handler = async (event) => {
  const response = {
    statusCode: 200,
    body: JSON.stringify({ message: "Hello from Node!" }),
  };
  return response;
};
