import json
import random

HANDLES = """    sparkleforests
    foozlebooze
    freerunlives
    relaxfavor
    cansparkle
    tastycupcakey
    patiencecomic
    whoopsschnoop
    breathesmooch
    poodlebreathe
    anticipatelove
    pleasureblossom
    exuberantwin
    restoremuffins
    tiggytigbeautiful
    piggildyblithe
    fallmilk
    luvbubbles
    anticipatesnurf
    successwobbly
    celebrationrenewal
    dadopen
    lolholiday
    duhhome
    paddywackalive
    awesomecheer
    hallelujahmuffins
    humorpiggildy
    jellybeanswhiffle
    ticklefriendship
    walkcongratulations
    smittengenerosity
    hornswogglemild
    inspiredjiggly
    restamaze
    hehedaisies
    burkinaawesome
    hehecelebration
    beancolors
    sweetheartjumbo
    cakesplonk
    alivestars
    pierainbow
    snowflakezzzzz
    cozylego
    beanglume
    amusedcompanionship
    bloominglovely
    enjoyrapture
    freshsunrise
    meeppiglet
    doodiegood
    hehecool
    blossomrhubarb
    hopefulwubblybuns
    glitterlovestruck
    zzzzzthanks
    dadgood
    woohoonap
    bumblenature
    dearbefuddled
    glittersoothing
    toysboondoggle
    chomptravel
    magicalidea
    puppycool
    toysbunny
    lightheartedsparkle
    wishessnowflakes
    bamboozledfortunate
    kittygood
    tinytoesred
    cupcakecuddle
    warmthsnaffle
    prinkyhoney
    rosesgarden
    milkcontent
    hubbatehe
    birthdaypleased
    sockemboppercool
    tastyfall
    soothingsnurfle
    kissesbreathe
    bahookiepresents
    ideadobby
    sweetheartroses
    snowflakewhoops
    cakeswallop
    rosesoft
    pleasedchildhood
    canoodleamaze
    dreamspeace
    strawberriesplay
    marshmallowsharmony
    familytoot
    altruiskinky
    singingocean
    nostalgiccakes
    mumbograce
    positivepie
    chocolatepopsicle
    llamaboondoggle
    grasshiney
    waterballoonsglitter
    glumelily
    presentssurprise
    sparklerose"""

PERMALINKS = """    myblog.com/post-title
    myblog.com/10-tips-for-successful-blogging
    myblog.com/how-to-start-a-food-blog
    myblog.com/the-ultimate-guide-to-seo
    myblog.com/top-5-destinations-for-summer-travel
    myblog.com/recipes-for-healthy-living
    myblog.com/the-art-of-storytelling
    myblog.com/10-must-read-books-for-2023
    myblog.com/5-ways-to-boost-productivity-at-work
    myblog.com/a-beginner's-guide-to-photography
    myblog.com/10-effective-marketing-strategies-for-small-businesses
    myblog.com/the-importance-of-self-care
    myblog.com/how-to-plan-a-dream-wedding
    myblog.com/the-power-of-positive-thinking
    myblog.com/10-tips-for-maintaining-a-healthy-lifestyle
    myblog.com/the-future-of-artificial-intelligence
    myblog.com/a-guide-to-creating-engaging-content
    myblog.com/the-benefits-of-meditation
    myblog.com/10-essential-travel-gadgets
    myblog.com/how-to-overcome-procrastination
    myblog.com/the-rise-of-influencer-marketing
    myblog.com/7-steps-to-building-a-successful-startup
    myblog.com/the-impact-of-social-media-on-society
    myblog.com/a-guide-to-plant-based-diet
    myblog.com/the-art-of-public-speaking
    myblog.com/10-tips-for-effective-time-management
    myblog.com/how-to-create-a-stunning-website
    myblog.com/the-importance-of-continuous-learning
    myblog.com/5-ways-to-deal-with-stress
    myblog.com/a-guide-to-freelancing-success
    myblog.com/the-future-of-virtual-reality
    myblog.com/10-tips-for-healthy-skin
    myblog.com/the-power-of-gratitude
    myblog.com/how-to-build-strong-relationships
    myblog.com/top-5-photography-techniques
    myblog.com/the-impact-of-technology-on-education
    myblog.com/10-must-have-apps-for-productivity
    myblog.com/a-guide-to-home-decorating
    myblog.com/the-benefits-of-yoga
    myblog.com/how-to-start-an-online-store
    myblog.com/the-rise-of-remote-work
    myblog.com/10-tips-for-effective-email-marketing
    myblog.com/a-guide-to-healthy-eating
    myblog.com/the-art-of-negotiation
    myblog.com/the-impact-of-climate-change
    myblog.com/5-ways-to-boost-creativity
    myblog.com/a-guide-to-successful-networking
    myblog.com/the-future-of-blockchain-technology
    myblog.com/10-tips-for-gaining-financial-independence
    myblog.com/the-importance-of-emotional-intelligence
    myblog.com/how-to-start-a-podcast
    myblog.com/the-power-of-mentorship
    myblog.com/7-ways-to-live-a-meaningful-life
    myblog.com/a-guide-to-traveling-on-a-budget
    myblog.com/the-impact-of-art-on-society
    myblog.com/10-tips-for-effective-team-management
    myblog.com/how-to-build-a-strong-personal-brand
    myblog.com/the-benefits-of-mindfulness-meditation
    myblog.com/5-ways-to-boost-your-career
    myblog.com/a-guide-to-effective-communication
    myblog.com/the-future-of-electric-vehicles
    myblog.com/10-tips-for-creating-engaging-social-media-content
    myblog.com/the-importance-of-physical-fitness
    myblog.com/how-to-write-a-bestselling-novel
    myblog.com/the-power-of-positive-parenting
    myblog.com/5-essential-travel-accessories
    myblog.com/a-guide-to-mastering-public-speaking
    myblog.com/the-impact-of-automation-on-jobs
    myblog.com/10-tips-for-healthy-weight-loss
    myblog.com/the-benefits-of-morning-routine
    myblog.com/how-to-start-a-successful-youtube-channel
    myblog.com/the-power-of-effective-leadership
    myblog.com/7-ways-to-cultivate-happiness
    myblog.com/a-guide-to-travel-photography
    myblog.com/the-future-of-space-exploration
    myblog.com/10-tips-for-improving-website-traffic
    myblog.com/how-to-build-a-profitable-online-business
    myblog.com/the-importance-of-mental-health-awareness
    myblog.com/5-ways-to-stay-motivated
    myblog.com/a-guide-to-entrepreneurship
    myblog.com/the-impact-of-social-media-on-mental-health
    myblog.com/10-tips-for-effective-goal-setting
    myblog.com/the-benefits-of-daily-meditation
    myblog.com/how-to-learn-a-new-language
    myblog.com/the-power-of-positivity
    myblog.com/5-essential-gardening-tips
    myblog.com/a-guide-to-effective-time-blocking
    myblog.com/the-future-of-augmented-reality
    myblog.com/10-tips-for-achieving-work-life-balance
    myblog.com/the-importance-of-digital-marketing
    myblog.com/how-to-start-a-fashion-blog
    myblog.com/the-power-of-creative-thinking
    myblog.com/7-ways-to-boost-your-productivity
    myblog.com/a-guide-to-healthy-sleep-habits
    myblog.com/the-impact-of-artificial-intelligence-on-business
    myblog.com/10-tips-for-effective-email-management
    myblog.com/how-to-build-a-strong-team-culture
    myblog.com/the-benefits-of-journaling
    myblog.com/5-ways-to-improve-your-presentation-skills
    myblog.com/a-guide-to-effective-negotiation-strategies"""

COMMENTS = """    "I never realized how important budgeting is until I read this article. Thanks for the valuable advice!"
    "Managing my debts has always been a struggle, but your blog has given me some great ideas on how to tackle them."
    "I never understood the concept of compound interest until now. It's amazing how it can work for or against you!"
    "Your tips on saving money are so practical and easy to follow. Can't wait to see the results!"
    "Investing seemed so intimidating to me, but your explanations have made it much clearer. I'm ready to get started!"
    "I've been struggling with credit card debt, and your blog has given me hope and a plan to pay it off. Thank you!"
    "Your breakdown of different investment options has helped me choose the right path for my financial goals."
    "I never thought about the importance of an emergency fund until I read your article. It's time to start saving!"
    "Your blog is my go-to resource for all things finance. Keep up the great work!"
    "I appreciate the way you simplify complex financial concepts. It makes it easier for beginners like me to understand."
    "Your tips on negotiating better deals have saved me a lot of money. Thank you for sharing your expertise!"
    "I've always been hesitant about investing, but your blog has given me the confidence to take the plunge."
    "Your blog has motivated me to start tracking my expenses and make better financial decisions. Thank you!"
    "I never realized the impact of small daily expenses until I read your article. It's eye-opening!"
    "Your budgeting templates have been a lifesaver. I finally feel in control of my finances!"
    "I've always been curious about real estate investing, and your blog has provided valuable insights. Thank you!"
    "Your articles on financial independence have inspired me to work towards achieving my own financial freedom."
    "Your tips on improving credit scores have helped me qualify for a better interest rate. Thank you!"
    "I love how your blog covers a wide range of financial topics. It's a one-stop resource for me!"
    "Your advice on how to save money on groceries has helped me cut down my expenses without sacrificing quality."
    "Your blog is my daily dose of financial wisdom. Keep up the excellent work!"
    "I never thought I could negotiate my bills until I read your article. It's amazing how much I've saved!"
    "Your explanations of investment terms have made it much easier for me to understand financial jargon. Thank you!"
    "Your blog has given me the confidence to start my own business. Your financial tips are invaluable!"
    "Your tips on avoiding common money mistakes have saved me from making some costly errors. Thank you!"
    "Your blog has become my financial roadmap. I'm grateful for the guidance you provide!"
    "Your articles on retirement planning have given me a clear roadmap for a financially secure future."
    "I've always been clueless about taxes, but your blog has shed some much-needed light on the topic."
    "Your advice on building an emergency fund has been a game-changer for me. I feel much more secure now."
    "Your blog has taught me the importance of diversifying my investment portfolio. It's crucial for long-term success."
    "I've always been overwhelmed by financial planning, but your step-by-step guides have made it much more manageable."
    "Your tips on reducing unnecessary expenses have helped me free up money for saving and investing. Thank you!"
    "Your blog is my financial mentor. I can't thank you enough for sharing your knowledge and insights."
    "Your advice on choosing the right credit card has saved me from falling into debt traps. Thank you for the guidance!"
    "Your articles on passive income have inspired me to explore alternative streams of revenue. You're truly motivating!"
    "I've always been skeptical about financial advisors, but your blog has given me the tools to manage my finances independently."
    "Your blog is a treasure trove of financial wisdom. I'm grateful for all the information you share!"
    "Your tips on improving financial discipline have transformed my spending habits. My bank account is thanking you!"
    "Your blog has taught me that financial success is attainable with the right knowledge and discipline. Thank you for being an inspiration!"
    "Your explanations of investment risks have helped me make informed decisions. Your expertise is invaluable!"
    "Your blog is my go-to resource for all things money-related. I've learned so much from your articles."
    "Your advice on automating savings has made it easier for me to stick to my financial goals. Thank you for the practical tips!"
    "Your insights on the psychology of money have changed my perspective on wealth and abundance. Thank you for the eye-opening articles!"
    "I never realized the importance of having an estate plan until I read your blog. Your reminders are crucial for financial well-being."
    "Your tips on reducing student loan debt have given me hope. I can't wait to be debt-free!"
    "Your articles on frugal living have helped me embrace a more minimalist lifestyle. My bank account and I are grateful!"
    "Your blog has taught me the value of delayed gratification. I'm starting to see the benefits in my financial life."
    "Your advice on navigating the stock market has helped me make smarter investment decisions. Thank you for sharing your expertise!"
    "Your tips on finding the right insurance policies have saved me money while ensuring adequate coverage. Thank you for the guidance!"
    "Your blog has become my financial bible. Your insights and tips have transformed the way I manage money."
    "I've always struggled with impulse buying, but your articles on mindful spending have given me the tools to overcome it. Thank you!"
    "Your blog has helped me regain control of my finances. I finally feel empowered to make smarter money choices."
    "Your advice on negotiating a salary raise has given me the confidence to have that conversation with my boss. Thank you for the valuable tips!"
    "I love how your blog combines practical advice with motivational content. It keeps me inspired on my financial journey."
    "Your articles on entrepreneurship and financing a business have been a guiding light for my startup. Thank you for sharing your knowledge!"
    "Your tips on improving financial literacy have made me a more informed consumer. Your blog is a fantastic resource!"
    "Your blog has taught me the importance of setting financial goals and working towards them systematically. I'm excited to achieve my milestones!"
    "Your advice on planning for retirement early has given me peace of mind. I'm grateful for the foresight your blog provides."
    "Your articles on overcoming debt have given me hope during challenging times. Thank you for your encouragement and strategies!"
    "Your blog has taught me that financial education is a lifelong journey. I'm grateful for the continuous learning your articles provide."
    "Your tips on creating a realistic budget have helped me gain control over my finances. I finally feel financially stable!"
    "Your blog is a goldmine of practical advice. I've implemented many of your strategies and seen positive results. Thank you for sharing your wisdom!"
    "Your advice on investing in index funds has simplified the world of investing for me. I feel more confident about my choices now."
    "Your articles on overcoming financial setbacks have motivated me to bounce back from my own challenges. Thank you for the encouragement!"
    "Your blog has become my trusted source for financial news and updates. I appreciate your thorough research and analysis."
    "Your tips on teaching kids about money have made it easier for me to instill good financial habits in my children. Thank you for the valuable insights!"
    "Your blog has taught me that small changes can lead to significant financial improvements. I'm excited to implement more of your suggestions!"
    "Your advice on navigating student loans has been a lifesaver. I'm finally making progress towards paying off my debt. Thank you!"
    "Your articles on investing in the stock market have given me the confidence to start building my portfolio. Your guidance is appreciated!"
    "Your blog has opened my eyes to the possibilities of passive income. I'm eager to explore different avenues and diversify my revenue streams."
    "Your tips on reducing monthly expenses have given me breathing room in my budget. I'm grateful for the practical suggestions!"
    "Your advice on avoiding common financial scams has saved me from falling victim to fraudulent schemes. Thank you for keeping us informed!"
    "Your blog has helped me overcome my fear of investing. Your explanations make it accessible and less intimidating."
    "Your tips on negotiating lower interest rates have helped me save money on my loans. Thank you for the empowering advice!"
    "Your articles on financial planning for couples have facilitated important conversations with my partner. We're on the same page now, thanks to your guidance."
    "Your blog is my daily dose of financial inspiration and education. I can't thank you enough for the valuable content you provide!"
    "Your advice on building a strong credit history has given me a roadmap for achieving my financial goals. Thank you for the guidance!"
    "Your tips on cutting down unnecessary expenses have helped me save for my dream vacation. Your blog is a game-changer!"
    "Your articles on understanding investment risk have made me a more cautious and informed investor. Thank you for sharing your expertise!"
    "Your blog has given me a fresh perspective on money management. I'm excited to implement your strategies and achieve financial freedom."
    "Your advice on avoiding common money pitfalls has saved me from making costly mistakes. Thank you for the insightful guidance!"
    "Your articles on side hustles have inspired me to find additional streams of income. Your blog is a constant source of motivation!"
    "Your blog has helped me develop a positive relationship with money. Thank you for promoting financial well-being and abundance!"
    "Your tips on negotiating better insurance rates have saved me a significant amount of money. I appreciate the practical advice!"
    "Your advice on managing financial stress has been a lifeline during difficult times. Thank you for your compassion and wisdom!"
    "Your articles on financial planning for retirement have given me peace of mind. I'm confident about my financial future, thanks to your guidance!"
    "Your blog has transformed the way I approach money. I'm more conscious about my spending and saving habits. Thank you for the positive impact!"
    "Your advice on diversifying my investment portfolio has helped me reduce risk and maximize returns. Your expertise is appreciated!"
    "Your articles on entrepreneurship and financing a business have been my go-to resource as I navigate the world of startups. Thank you for the valuable insights!"
    "Your tips on avoiding lifestyle inflation have helped me maintain a healthy financial balance. I'm grateful for the reminders!"
    "Your blog has made personal finance feel less overwhelming. Your practical advice is invaluable for someone like me who's just starting on this journey."
    "Your advice on creating a financial plan has given me a clear roadmap to achieve my goals. Thank you for the guidance and motivation!"
    "Your articles on saving for education expenses have helped me plan for my children's future. Your blog is a valuable resource for parents!"
    "Your tips on maximizing credit card rewards have helped me earn significant perks. I appreciate the insider knowledge you share!"
    "Your blog has opened my eyes to the power of investing. I'm excited to grow my wealth and secure my financial future."
    "Your advice on building an emergency fund has saved me from financial stress during unexpected times. Thank you for the peace of mind!"
    "Your articles on financial independence have inspired me to prioritize my long-term financial well-being. I'm excited to achieve financial freedom!"
    "Your blog is my go-to resource for all things finance. Your articles are well-researched, informative, and easy to understand."
    "Your advice on reducing debt and increasing savings has transformed my financial situation. Thank you for the life-changing tips!"
    "Your blog has made me more mindful of my financial choices. I now consider the long-term implications before making any financial decision."
    "Your barbecue recipes are always a hit at my backyard gatherings. Thanks for sharing your delicious creations!"
    "I never knew grilling could be so versatile until I discovered your blog. Your recipes have opened up a whole new world of flavors for me."
    "Your tips on achieving the perfect grill marks have taken my barbecue game to the next level. My steaks have never looked better!"
    "Your blog is my go-to resource for barbecue inspiration. I can always count on finding mouthwatering recipes and helpful techniques."
    "Your step-by-step guides make it so easy for beginners like me to master the art of barbecuing. Thank you for your clear instructions!"
    "I tried your smoked ribs recipe, and they turned out incredible. I'm officially a barbecue aficionado thanks to your blog!"
    "Your recommendations for different types of wood for smoking have elevated the flavors of my grilled meats. I'm forever grateful for your expertise."
    "Your blog has inspired me to experiment with different marinades and rubs. My taste buds have never been happier!"
    "Your tips on controlling grill temperature have saved me from many burnt dinners. Thank you for sharing your knowledge!"
    "Your barbecue sauce recipe is hands down the best I've ever tasted. I've even started making extra batches to share with friends and family."
    "Your blog has sparked my passion for outdoor cooking. I can't wait to fire up the grill and try your latest recipe!"
    "Your recommendations for grilling accessories have made my barbecue sessions more convenient and enjoyable. Thank you for the valuable suggestions!"
    "Your articles on different grilling techniques have broadened my skills and made me a more versatile grill master. Keep the tips coming!"
    "Your blog is my ultimate grilling companion. I appreciate the variety of recipes and the attention to detail in your instructions."
    "Your tips on choosing the right cuts of meat for grilling have helped me make delicious and tender dishes. I'm forever grateful for your expertise."
    "Your advice on cleaning and maintaining the grill has extended its lifespan and kept it in top condition. Thank you for the maintenance tips!"
    "Your barbecue recipes always make me the hero of every cookout. My friends and family can't get enough of the flavors you share."
    "Your blog has given me the confidence to host barbecue parties. Your recipes and tips have made me the grill master among my friends!"
    "I never thought I could achieve restaurant-quality flavors at home until I discovered your blog. You've made barbecuing accessible to everyone."
    "Your recommendations for pairing barbecue dishes with the right sauces and sides have taken my meals to a whole new level. Thank you for the flavor combinations!"
    "Your blog has turned me into a barbecue enthusiast. I'm constantly trying new recipes and techniques thanks to your inspiring content."
    "Your tips on achieving the perfect balance of smoke and heat have transformed my barbecue results. My meats have never been juicier!"
    "Your blog has become my go-to source for grilling inspiration. I can always count on finding creative and delicious recipes to try."
    "Your advice on prepping the grill before cooking has improved the overall taste and presentation of my grilled dishes. Thank you for the pro tips!"
    "Your barbecue tutorials have helped me overcome my fear of grilling. I'm now confident in my skills and enjoy cooking outdoors."
    "Your blog has made me realize the importance of patience in barbecuing. Slow and steady truly wins the flavor race!"
    "Your homemade barbecue rub recipe is now a staple in my kitchen. It adds the perfect flavor to all my grilled meats."
    "Your tips on indirect grilling have allowed me to cook delicate foods that would have been impossible on direct heat. Thank you for expanding my options!"
    "Your blog has made me appreciate the art of barbecuing. It's not just about the food, but the whole experience and joy it brings."
    "Your recommendations for must-have grill tools have made my cooking process more efficient. I can't imagine barbecuing without them now."
    "Your tips on avoiding common grilling mistakes have saved me from many culinary disasters. Thank you for the invaluable advice!"
    "Your blog is my secret weapon for impressing guests with mouthwatering barbecue dishes. Thank you for making me the grill master of my social circle!"
    "Your recipes are always so well-balanced in terms of flavors. I love how you combine different spices and ingredients to create delicious marinades."
    "Your blog has taught me that barbecuing is an art that requires practice and patience. I'm grateful for the guidance you provide along the way."
    "Your recommendations for grilling seafood have taken my barbecue skills to the next level. I never thought I could achieve such delicate flavors on the grill."
    "Your blog is my grilling bible. I trust your expertise and appreciate the effort you put into sharing your knowledge with us."
    "Your advice on using a meat thermometer has made a world of difference in the doneness of my grilled meats. Thank you for the precision tips!"
    "Your recipes always make me look like a pro chef. I can't thank you enough for the delicious dishes you've introduced me to."
    "Your blog has become my one-stop-shop for all things barbecue. I've learned so much from your articles and recipes."
    "Your tips on achieving the perfect barbecue char on vegetables have made me fall in love with grilled veggies. Thank you for the inspiration!"
    "Your recommendations for homemade barbecue sauces have made me ditch store-bought ones for good. I love the customizable flavors you share."
    "Your blog is a treasure trove of grilling knowledge. I'm constantly learning something new and improving my skills thanks to your guidance."
    "Your step-by-step tutorials have made it easy for me to follow along and replicate your recipes. I appreciate the level of detail you provide."
    "Your advice on brining meat before grilling has given me juicier and more flavorful results. Thank you for the game-changing tip!"
    "Your blog has made me fall in love with the smoky aroma of barbecue. I can't get enough of the amazing flavors you help us achieve."
    "Your tips on achieving the perfect barbecue bark have transformed my brisket game. I'm now known for my delicious smoky creations!"
    "Your recommendations for different types of charcoal have helped me find the perfect fuel for my grill. The flavor profiles are incredible!"
    "Your blog has become my secret weapon for hosting memorable cookouts. Everyone raves about the food, and it's all thanks to you!"
    "Your articles on the science of grilling have deepened my understanding and appreciation for the craft. Thank you for sharing your knowledge!"
    "Your barbecue recipes are always a hit with my family. We look forward to trying new dishes and flavors together."
    "Your tips on maintaining grill hygiene have improved the longevity of my grill and the taste of my food. Thank you for the cleanliness reminders!"
    "Your blog has sparked my creativity in the kitchen. I now experiment with different flavors and ingredients, all inspired by your recipes."
    "Your advice on resting grilled meat before serving has made a world of difference in the juiciness and tenderness of my dishes. Thank you for the pro tip!"
    "Your blog has inspired me to start my own barbecue journey. I can't wait to learn and explore the world of grilling with your guidance."
    "Your barbecue recipes have become family favorites. Thank you for helping me create cherished memories around the grill."
    "Your tips on achieving a perfect sear have elevated my steak game. I now confidently cook steaks that rival those of high-end restaurants."
    "Your blog is my go-to resource for hosting barbecue parties. Your recipes and tips ensure a successful and delicious gathering every time."
    "Your recommendations for grilling desserts have expanded my repertoire. Grilled fruits and sweet treats are now a staple in my barbecues."
    "Your articles on different barbecue styles have made me appreciate the rich cultural heritage behind this cooking method. Thank you for the education!"
    "Your tips on managing grill flare-ups have saved me from many kitchen disasters. I'm grateful for your quick thinking solutions!"
    "Your blog is my ultimate source of inspiration when it comes to spicing up my barbecues. Thank you for the endless creativity!"
    "Your recipes are always straightforward and easy to follow. I appreciate how you simplify complex techniques for us home cooks."
    "Your tips on marinating meat have resulted in flavors that are out of this world. I'm constantly amazed by the depth of taste I achieve using your recipes."
    "Your blog has become my virtual mentor in the art of barbecuing. I'm grateful for the guidance and wisdom you share with us."
    "Your advice on proper grill maintenance has kept my equipment in top shape. It's as good as new, even after years of use!"
    "Your barbecue recipes have made me the star of neighborhood potlucks. I'm always asked for the secret behind my delicious dishes, and it's all thanks to you!"
    "Your blog has ignited my passion for exploring different grilling techniques. I'm eager to try new methods and expand my skills."
    "Your tips on smoking meats have given me a newfound appreciation for slow-cooked dishes. The flavors are simply incredible!"
    "Your recommendations for side dishes and sauces to accompany grilled meats have taken my meals to a whole new level. Thank you for the perfect pairings!"
    "Your blog is my go-to resource when I want to impress guests with a special barbecue feast. I can always count on finding unique and delightful recipes."
    "Your advice on grilling safety has made me more conscious of potential hazards and how to prevent them. Thank you for prioritizing our well-being!"
    "Your blog has inspired me to invest in a quality grill, and it has truly changed my cooking game. The results speak for themselves!"
    "Your tips on grilling pizza have revolutionized my homemade pizza nights. I can now achieve that crispy crust and smoky flavor I love."
    "Your barbecue tutorials are so detailed and easy to follow. I've learned more from your blog than from any other source. Thank you for being such a great teacher!"
    "Your recipes cater to different dietary preferences, and I love the variety you offer. I can always find something delicious to cook, no matter my guests' restrictions."
    "Your blog has made me realize that barbecuing is not just a summer activity. I now grill all year round and enjoy the flavors regardless of the season."
    "Your tips on achieving the perfect barbecue glaze have taken my dishes from good to outstanding. Thank you for sharing your secrets!"
    "Your recommendations for grilling vegetables have made me appreciate the versatility of the grill. I now enjoy plant-based barbecues too!"
    "Your blog has turned me into a barbecue enthusiast. I can't get enough of the smoky aromas and tantalizing flavors you introduce us to."
    "Your advice on proper knife handling during barbecuing has improved my safety in the kitchen. Thank you for the important reminders!"
    "Your barbecue recipes have become a family tradition. We gather around the grill, cook together, and enjoy the delicious fruits of our labor."
    "Your blog has taught me that barbecuing is not just about the food but also about the connections we build around the grill. Thank you for the heartwarming insights!"
    "Your tips on using different wood chips for smoking have allowed me to experiment with unique flavors. I love the variety and surprises each time I cook."
    "Your recipes are always a hit with my friends. They can't believe I made such tasty barbecue dishes, all thanks to your guidance."
    "Your blog has awakened my curiosity for trying new ingredients and flavors in my barbecues. Thank you for expanding my culinary horizons!"
    "Your advice on creating a barbecue timeline has helped me stay organized during large cookouts. I can now serve hot and delicious food without the stress."
    "Your blog has made me realize that barbecuing is not just about the main course but also about the creative side dishes and desserts. Thank you for the complete experience!"
    "Your tips on using different grilling techniques for different cuts of meat have made me appreciate the nuances of barbecue. I now understand the importance of cooking methods."
    "Your recipes have become my family's favorites. We love gathering around the grill and creating delicious memories together."
    "Your blog has given me the confidence to experiment and put my own twist on barbecue recipes. I'm grateful for the creative freedom you inspire."
    "Your tips on temperature control have made a huge difference in my barbecue results. I now have more control over the cooking process and can achieve the perfect doneness."
    "Your barbecue sauce recipes are legendary! I've started making large batches and gifting them to friends and family. Everyone wants a taste!"
    "Your blog is my constant source of inspiration when it comes to planning barbecue menus. I appreciate the diversity of flavors and cuisines you explore."
    "Your advice on choosing the right grill for my needs and budget has been invaluable. I'm now a proud owner of a grill that suits me perfectly."
    "Your recipes always make my taste buds dance with joy. I can't thank you enough for sharing your culinary expertise with us."
    "Your blog has made me realize that barbecuing is not just about the final dish but also about the process and the joy it brings. Thank you for reminding me to enjoy the journey!"
    "Your tips on achieving consistent heat distribution have made a noticeable difference in the quality of my grilled dishes. I'm grateful for your insights."
    "Your blog has introduced me to new grilling techniques and equipment. I'm constantly learning and improving my skills thanks to your guidance."
    "Your recipes are so versatile. I love that I can adapt them to my personal taste preferences and still achieve outstanding results."
    "Your advice on the importance of patience in barbecuing has made me slow down and enjoy the process. The flavors that develop are worth the wait!"
    "Your blog has made me appreciate the importance of quality ingredients in barbecuing. I now seek out the best cuts of meat and freshest produce for my grilling adventures."
    "Your tips on using marinades to tenderize meat have revolutionized my barbecue game. I can now achieve succulent and flavorful dishes every time."
    "Your barbecue recipes are so creative. I love the unexpected flavor combinations you introduce. They always keep me excited to try something new."
    "Your blog has turned me into a barbecue enthusiast. I now look forward to weekends just so I can fire up the grill and try your latest recipes."
    "Your advice on using indirect heat for low and slow cooking has produced the juiciest and most tender meats I've ever tasted. Thank you for sharing your expertise!"
    "Your recommendations for grilling tools and accessories have made my barbecuing sessions much more enjoyable. I feel like a pro with all the right gear."
    "Your blog has helped me overcome my fear of grilling seafood. I'm now confident in cooking delicate fish and shellfish on the grill."
    "Your tips on adding a smoky twist to classic dishes have added a whole new dimension to my cooking. I love experimenting with smoky flavors in unexpected places."
    "Your recipes are always a hit at my family gatherings. I've become the designated grill master, all thanks to your delicious creations."
    "Your blog has become my trusted resource for all things barbecuing. I appreciate the in-depth knowledge and passion you bring to the table."
    "Your advice on achieving the perfect grill marks has elevated the presentation of my grilled dishes. It's the little details that make all the difference."
    "Your barbecue sauce recipes have become a staple in my kitchen. I love that I can customize the flavors and create my signature sauces."
    "Your blog has inspired me to explore different regional barbecue styles. I've discovered a whole new world of flavors and techniques through your articles."
    "Your tips on proper meat resting have made my grilled steaks unbelievably tender. I can't believe I used to skip this important step before!"
    "Your recommendations for pairing barbecue with the right beverages have elevated my dining experience. The combinations you suggest are always spot-on."
    "Your blog has taught me that barbecuing is not just about the recipes but also about the community. I appreciate the sense of belonging your platform provides."
    "Your tips on grill cleaning and maintenance have made the process much less daunting. I now take pride in keeping my grill in top shape."
    "Your barbecue recipes have become a hit among my friends. I'm always asked for the secret behind my delicious creations, and I proudly direct them to your blog."
    "Your blog has opened my eyes to the endless possibilities of barbecuing. I now feel confident in exploring different flavors and techniques."
    "Your advice on using rubs to enhance the flavor of grilled meats has been a game-changer. I can't imagine grilling without them now."
    "Your recipes have become a regular part of our family meals. I love how your flavors bring us together around the grill."
    "Your blog has taught me the importance of proper grill maintenance. I now take better care of my equipment, and it pays off in the quality of my grilled dishes."
    "Your tips on achieving the perfect barbecue crust have taken my ribs to the next level. I'm now known for my fall-off-the-bone tender and flavorful creations."
    "Your recommendations for grilling techniques for different types of vegetables have made me appreciate the natural sweetness and smoky flavors of grilled veggies."
    "Your blog has become my go-to resource for barbecue inspiration. I can always find a recipe that matches my mood and the ingredients I have on hand." """


SPAM_COMMENTS = [
    "SMS SERVICES. for your inclusive text credits, pls goto www.comuk.net login= 3qxj9 unsubscribe with STOP, no extra charge. help 08702840625.COMUK. 220-CM2 9AE",
    "PRIVATE! Your 2003 Account Statement for 07808247860 shows 800 un-redeemed S. I. M. points. Call 08719899229 Identifier Code: 40411 Expires 06/11/04",
    "You are awarded a SiPix Digital Camera! call 09061221061 from landline. Delivery within 28days. T Cs Box177. M221BP. 2yr warranty. 150ppm. 16 . p p£3.99",
    "PRIVATE! Your 2003 Account Statement for shows 800 un-redeemed S.I.M. points. Call 08718738001 Identifier Code: 49557 Expires 26/11/04",
    "Want explicit SEX in 30 secs? Ring 02073162414 now! Costs 20p/min Gsex POBOX 2667 WC1N 3XX",
    "ASKED 3MOBILE IF 0870 CHATLINES INCLU IN FREE MINS. INDIA CUST SERVs SED YES. L8ER GOT MEGA BILL. 3 DONT GIV A SHIT. BAILIFF DUE IN DAYS. I O £250 3 WANT £800",
    "Had your contract mobile 11 Mnths? Latest Motorola, Nokia etc. all FREE! Double Mins & Text on Orange tariffs. TEXT YES for callback, no to remove from records.",
    "REMINDER FROM O2: To get 2.50 pounds free call credit and details of great offers pls reply 2 this text with your valid name, house no and postcode",
    "This is the 2nd time we have tried 2 contact u. U have won the £750 Pound prize. 2 claim is easy, call 087187272008 NOW1! Only 10p per minute. BT-national-rate.",
]

users = []
for idx, handle in enumerate(HANDLES.split("\n")):
    handle = handle.strip()
    users.append(
        {
            "id": idx,
            "handle": f"@{handle}",
            "username": handle,
        }
    )

with open("./users.json", "w", encoding="utf-8") as file:
    json.dump(users, file)

posts = []
for idx, permalink in enumerate(PERMALINKS.split("\n")):
    permalink = permalink.strip()
    title = permalink.split("/")[-1].replace("-", " ")
    posts.append(
        {
            "id": idx,
            "url": permalink,
            "title": title,
        }
    )

with open("./posts.json", "w", encoding="utf-8") as file:
    json.dump(posts, file)

comments = []
for _, comment in enumerate(COMMENTS.split("\n")):
    comments.append({"content": comment.strip().strip('"')})

with open("./comments.json", "w", encoding="utf-8") as file:
    json.dump(comments, file)

spam_comments = []
for comment in SPAM_COMMENTS:
    spam_comments.append({"content": comment.strip().strip('"')})

with open("./spam_comments.json", "w", encoding="utf-8") as file:
    json.dump(spam_comments, file)
