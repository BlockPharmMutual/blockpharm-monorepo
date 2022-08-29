import {
  Text,
  Card,
  Button,
  Spacer,
  Row,
  Badge,
  Grid,
} from "@nextui-org/react";

type Props = {
  title?: string;
  isActive?: boolean;
};

export const MockItem = ({ title, isActive }: Props) => {
  return (
    <Card css={{ mw: "330px" }}>
      <Card.Header>
        <Grid.Container gap={0} justify="space-between">
          <Grid xs={6} justify="flex-start">
            <Text b>{title}</Text>
          </Grid>
          <Grid xs={6} justify="flex-end">
            {isActive ? (
              <Badge color="success" size="sm">
                Open
              </Badge>
            ) : (
              <Badge color="error" size="sm">
                Closed
              </Badge>
            )}
          </Grid>
        </Grid.Container>
      </Card.Header>
      <Card.Divider />
      <Card.Body css={{ py: "$10" }}>
        <Text>
          Some quick example text to build on the card title and make up the
          bulk of the card's content.
        </Text>
      </Card.Body>
      <Card.Divider />
      <Card.Footer>
        <Row justify="center">
          {/* <Button size="sm" light>
            Cancel
          </Button> */}
          <Button size="sm">Get Quote</Button>
        </Row>
      </Card.Footer>
    </Card>
  );
};
