const countdown = () => {
  // Date format is month date, year hours:minutes:seconds
  const countDate = new Date("December 10, 2021 11:00:00").getTime(); //returns in ms
  // get the difference between future date and current time
  const now = new Date().getTime();
  const gap = countDate - now;
  // how the fuck does time work
  const second = 1000;
  const minute = second * 60;
  const hour = minute * 60;
  const day = hour * 24;

  //now we have our gap and have the units of time
  // calculate the shit, add a math.floor to round down
  const textDay = Math.floor(gap / day);
  //example of % modulus: 18 % 2 = 0.
  //a%b will devide a by b and return the remainder
  // console.log((gap % day)/hour)
  const textHour = Math.floor((gap % day) / hour);
  const textMinute = Math.floor((gap % hour) / minute);
  const textSecond = Math.floor((gap % minute) / second);
  // console.log(textDay, textHour, textMinute, textSecond);

  // update our html
  document.querySelector(".day").innerText = textDay;
  document.querySelector(".hour").innerText = textHour;
  document.querySelector(".minute").innerText = textMinute;
  document.querySelector(".second").innerText = textSecond;

  // console.log(gap); //regularly update
  // if (gap < 10000) {
  //     launchtheBullshit()
  // }
};

// something about this seems really inefficient to call and set all
// those variables in the original countdown function, perhaps next
// step (after a 0 suprise yay screen) could be refactoring?
setInterval(countdown, 1000);
