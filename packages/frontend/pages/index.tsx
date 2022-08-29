import { Grid, Card, Spacer, Text } from "@nextui-org/react";
import type { NextPage } from "next";
import Head from "next/head";
import styles from "../styles/Home.module.css";
import { Layout } from "./Layout";
import { MockItem } from "../components/mockItem/MockItem";
import { Navigation } from "../components/navigation/Navigation";
import { Footer } from "../components/footer/Footer";

const Home: NextPage = () => {
  return (
    <div className={styles.container}>
      <Head>
        <title>BlockPharm Mutual</title>
        <meta
          name="BlockPharm Mutual"
          content="Blockchain based insurance for the pharmaceutical industry"
        />
        <link rel="icon" href="/favicon.svg" />
      </Head>
      <Navigation />
      <Layout>
        <Grid.Container gap={4} justify="center">
          <Grid.Container gap={4} justify="center" alignContent="center">
            <Spacer x={-4} />
            <Grid xs={10} css={{ h: "200px" }}>
              <Card
                variant="bordered"
                css={{
                  padding: "$10",
                  justifyContent: "center",
                  alignItems: "center",
                }}
              >
                <Text h2>Some hero section explaining stuff with diagrams</Text>
              </Card>
            </Grid>
          </Grid.Container>
          <Grid xs={4}>
            <MockItem title="LDX <-> DXB" isActive={true} />
          </Grid>
          <Grid xs={4}>
            <MockItem title="LDN <-> LAX" isActive={false} />
          </Grid>
          <Grid xs={4}>
            <MockItem title="LDN <-> GHA" isActive={false} />
          </Grid>
          <Grid xs={4}>
            <MockItem title="LDN <-> IRQ" isActive={false} />
          </Grid>
          <Grid xs={4}>
            <MockItem title="PKS <-> IRK" isActive={false} />
          </Grid>
          <Grid xs={4}>
            <MockItem title="PKS <-> SEG" isActive={false} />
          </Grid>
        </Grid.Container>
      </Layout>

      <Footer />
    </div>
  );
};

export default Home;
