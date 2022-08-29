import { Container, Spacer, styled } from "@nextui-org/react";

export const Layout = ({ children }) => (
  <Box
    css={{
      maxW: "100%",
      position: "relative",
      overflow: "visible scroll",
    }}
  >
    <Spacer y={0.8} />
    <Container
      as="main"
      display="flex"
      direction="row"
      justify="center"
      alignItems="baseline"
      style={{ height: "80vh" }}
    >
      {children}
    </Container>
  </Box>
);

export const Box = styled("div", {
  boxSizing: "border-box",
});
