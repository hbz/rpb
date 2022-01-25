name := "rpb"

version := "0.1.0-SNAPSHOT"

scalaVersion := "2.11.11"

resolvers += Resolver.mavenLocal

libraryDependencies ++= Seq(
  "org.metafacture" % "metafacture-io" % "5.3.1",
  "org.metafacture" % "metafacture-strings" % "5.3.1",
  "org.metafacture" % "metafacture-json" % "5.3.1",
  "org.metafacture" % "metafacture-flux" % "5.3.1",
  "org.metafacture" % "metafacture-triples" % "5.3.1",
  "org.metafacture" % "metafix" % "0.2.0-SNAPSHOT"
)

lazy val root = (project in file(".")).enablePlugins(PlayJava)

javacOptions ++= Seq("-source", "1.8", "-target", "1.8")

import com.typesafe.sbteclipse.core.EclipsePlugin.EclipseKeys

EclipseKeys.projectFlavor := EclipseProjectFlavor.Java // Java project. Don't expect Scala IDE
EclipseKeys.createSrc := EclipseCreateSrc.ValueSet(EclipseCreateSrc.ManagedClasses, EclipseCreateSrc.ManagedResources) // Use .class files instead of generated .scala files for views and routes
EclipseKeys.preTasks := Seq(compile in Compile) // Compile the project before generating Eclipse files, so that .class files for views and routes are present

trapExit := false
