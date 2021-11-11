import AnswerTypes from "./AnswerTypes.js";

const Quizzes = [
  {
    courseCode: "LINK101",
    courseName: "Chainlink 101",
    associatedLessonName:
      "Chainlink Lesson 1 (Sidechain Hackathon, Everybody!)",
    url: "https://youtu.be/ruKhSTFtsro?t=268",
    courseDescription:
      "Evaluation of fundamental skills in English and hackathon readiness",
    questions: [
      {
        q: "How is Sergei?",
        type: AnswerTypes.MC,
        options: [
          "Dope as a whip",
          "Funny you ask...[long story ensues]",
          "Doing well Patrick, how are you?",
          "Not bad, and you?",
        ],
        a: 1,
      },
      {
        q: "What is he super excited to see?",
        type: AnswerTypes.MC,
        options: [
          "'Flavor in the sauce', 'biscuits for the buns'",
          "Upcoming Musical Interludes by Slow News x Tippi Fifestarr",
          "'What everyone builds', 'What we are able to achieve out of this hackathon'",
          "Doing well",
        ],
        a: 2,
      },
      {
        q: "How can we generate something unique and nuanced?",
        type: AnswerTypes.MC,
        options: [
          "Put our best foot forward",
          "Iterate a few times",
          "Truth-based society",
          "Decentralized systems",
          "Decentralized consensus",
          "All of the above",
        ],
        a: 5,
      },
      {
        q: "What's the difference between Cryptographic Truth and Definitive Proof?",
        type: AnswerTypes.TXT,
        a: "...",
      },
    ],
  },
  {
    courseCode: "MATH101",
    courseName: "Math 101",
    associatedLessonName: "Math Lesson 1 (Kids)",
    url: "https://www.youtube.com/watch?v=igcoDFokKzU",
    courseDescription: "Evaluation of basic mathematical skills",
    questions: [
      {
        q: "The P in PEDMAS stands for ______.",
        type: AnswerTypes.MC,
        options: ["Point", "Primary", "Pentagon", "Parenthesis"],
        a: 3,
      },
      {
        q: "Complete the statement: 2 + 2 = _",
        type: AnswerTypes.NUM,
        a: 4,
      },
      {
        q: "Which of the following is a basic mathematic operation?",
        type: AnswerTypes.MC,
        options: [
          "Addition",
          "Subtraction",
          "Multiplication",
          "Division",
          "All of the above",
        ],
        a: 4,
      },
    ],
  },
];

export default Quizzes;
