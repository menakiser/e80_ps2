# e80_ps2
ECON 80 PS 2

Notes on 1/29:
 - We're assuming every individual is a unique household.
 - Raw trends plotting total or average number of children per year (im thinking two panels treated and untreated)

Questions for Doug 30/10:
- Assumption that each person is different HH? Ok?
- Run by him  outcomes (we include young children becasuse age of youngest child is higher than own age;) and that we are including medicaid and insurance uptake additional to child outcomes
- We are using state & survey year FE, but what is the reasoning behind including state#relative year (-1, 0, 1)?


Answers from Doug 10/30:
- Assumption that each person is different HH? Ok? "I did not include household variable? Whoops, just roll with it" Assumption is ok: assume each obs is a hh, we're not doing hh se so doesn't matter a ton, maybe mention in write up.
- Corrected the specification per Doug's suggestion. the var expansion and post is absorbed by state and year FE. FE have been corrected
- possible heterogeneity: by state characterisitics, poor state, red state, educated state. idk if we can bring additional data so it's not just based on our sample of youngsters. He mentioned we can try this but only if we have an interesting narrative
- outcome vars: they all look ok and we can think of the number of children as the stock and amount of new babies as flow
- Control vars: Net controls make sens: Sex, Age, Race, Hispanic, education. Some listed controls could be outcomes:
    * Marital Status (are people more likely to get married to accesss medicaid through their spouse or meet income threshold),
    * Employment status, Income, Full-time worker dummy (do people work less because they do not need to cover their medical expenses anymore), Income (same logic as emplo)

thoughts:
- what do we feel about controling for having medicaid post exposure? triple dif or just control?

\begin{comment}
Outcomes list:
\begin{itemize}
    \item Any coverage
    \item Medicaid
    \item Public insurance
    \item Employment insurance
    \item Number of children
    \item Dummy for new baby (<=1 years old)

\end{itemize}

Controls list:
\begin{itemize}
    \item Sex
    \item Age
    \item Race
    \item Hispanic
    \item Marital Status %we see changes in the balance table for this variable but not in the d-in-d
    \item Education
    \item Employment status
    \item Income
    \item Full-time worker dummy (40 hours or more a week)
\end{itemize}

Heterogeneity:
\begin{itemize}
    \item Sex
    \item Hispanic v. Not Hispanic
    \item Employment status
\end{itemize}
\end{comment}