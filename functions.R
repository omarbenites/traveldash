
# Define function for printing nice html tables
prettify <- function (the_table, remove_underscores_columns = TRUE, cap_columns = TRUE,
                      cap_characters = TRUE, comma_numbers = TRUE, date_format = "%B %d, %Y",
                      round_digits = 2, remove_row_names = TRUE, remove_line_breaks = TRUE,
                      data_table = TRUE, nrows = 5, download_options = FALSE, no_scroll = TRUE){
  column_names <- names(the_table)
  the_table <- data.frame(the_table)
  names(the_table) <- column_names
  classes <- lapply(the_table, function(x) {
    unlist(class(x))[1]
  })
  if (cap_columns) {
    names(the_table) <- Hmisc::capitalize(names(the_table))
  }
  if (remove_underscores_columns) {
    names(the_table) <- gsub("_", " ", names(the_table))
  }
  for (j in 1:ncol(the_table)) {
    the_column <- the_table[, j]
    the_class <- classes[j][1]
    if (the_class %in% c("character", "factor")) {
      if (cap_characters) {
        the_column <- as.character(the_column)
        the_column <- Hmisc::capitalize(the_column)
      }
      if (remove_line_breaks) {
        the_column <- gsub("\n", " ", the_column)
      }
    }
    else if (the_class %in% c("POSIXct", "Date")) {
      the_column <- format(the_column, format = date_format)
    }
    else if (the_class %in% c("numeric", "integer")) {
      the_column <- round(the_column, digits = round_digits)
      if (comma_numbers) {
        if(!grepl('year', tolower(names(the_table)[j]))){
          the_column <- scales::comma(the_column)
        }
      }
    }
    the_table[, j] <- the_column
  }
  if (remove_row_names) {
    row.names(the_table) <- NULL
  }
  if (data_table) {
    if (download_options) {
      if(no_scroll){
        the_table <- DT::datatable(the_table, options = list(#pageLength = nrows,
          scrollY = '300px', paging = FALSE,
          dom = "Bfrtip", buttons = list("copy", "print",
                                         list(extend = "collection", buttons = "csv",
                                              text = "Download"))), rownames = FALSE, extensions = "Buttons")
      } else {
        the_table <- DT::datatable(the_table, options = list(pageLength = nrows,
                                                             # scrollY = '300px', paging = FALSE,
                                                             dom = "Bfrtip", buttons = list("copy", "print",
                                                                                            list(extend = "collection", buttons = "csv",
                                                                                                 text = "Download"))), rownames = FALSE, extensions = "Buttons")
      }
      
    }
    else {
      if(no_scroll){
        the_table <- DT::datatable(the_table, options = list(#pageLength = nrows,
          scrollY = '300px', paging = FALSE,
          columnDefs = list(list(className = "dt-right",
                                 targets = 0:(ncol(the_table) - 1)))), rownames = FALSE)
      } else {
        the_table <- DT::datatable(the_table, options = list(pageLength = nrows,
                                                             columnDefs = list(list(className = "dt-right",
                                                                                    targets = 0:(ncol(the_table) - 1)))), rownames = FALSE)
      }
    }
  }
  return(the_table)
}

make_graph <- function(events){
  # Replacer
  replacer <- function(x){
    out <- data.frame(x = nodes$name, y = (1:nrow(nodes))-1)
    x <- data.frame(x = x)
    out <- left_join(x, out)
    return(out$y)
  }
  x <- events %>% group_by(Person, Counterpart) %>%
    tally %>%
    ungroup %>%
    mutate(Person = as.numeric(factor(Person)),
           Counterpart = as.numeric(factor(Counterpart)))
  nodes = data.frame("name" = 
                       c(sort(unique(events$Person)),
                         sort(unique(events$Counterpart))))
  nodes$group <-replacer(nodes$name)
  noder <- events %>% group_by(x = Person) %>% tally
  noderb <- events %>% group_by(x = Counterpart) %>% tally
  noder<- bind_rows(noder, noderb) %>%
    group_by(name = x) %>% summarise(size = sum(n))
  nodes <- left_join(nodes, noder, by = 'name')
  links = bind_rows(
    # Person to counterpart
    events %>% group_by(Person, Counterpart) %>%
      tally %>%
      ungroup %>%
      mutate(Person = replacer(Person),
             Counterpart = replacer(Counterpart)) %>%
      rename(a = Person,
             b = Counterpart)
  )

  nodes$size <- 1
  names(links) = c("source", "target", "value")
  # Plot
  forceNetwork(Links = links, 
               Nodes = nodes,
               Value = 'value',
               NodeID = "name", Group = "group",
               Nodesize="size",                                                    # column names that gives the size of nodes
               radiusCalculation = JS(" d.nodesize^2+10"),                         # How to use this column to calculate radius of nodes? (Java script expression)
               opacity = 1,                                                      # Opacity of nodes when you hover it
               opacityNoHover = 0.8,                                               # Opacity of nodes you do not hover
               colourScale = JS("d3.scaleOrdinal(d3.schemeCategory10);"),          # Javascript expression, schemeCategory10 and schemeCategory20 work
               fontSize = 17,                                                      # Font size of labels
               # fontFamily = "serif",                                               # Font family for labels
               
               # custom edges
               # Value="my_width",
               arrows = FALSE,                                                     # Add arrows?
               # linkColour = c("grey","orange"),                                    # colour of edges
               linkWidth = "function(d) { return (d.value^5)*0.4}",
               
               # layout
               linkDistance = 250,                                                 # link size, if higher, more space between nodes
               charge = -100,                                                       # if highly negative, more space betqeen nodes
               
               # -- general parameters
               height = NULL,                                                      # height of frame area in pixels
               width = NULL,
               zoom = TRUE,                                                        # Can you zoom on the figure
               # legend = TRUE,                                                      # add a legend?
               bounded = F, 
               clickAction = NULL)
}

make_sank <- function(events){
  x <- events %>% group_by(Person, Counterpart) %>%
    tally %>%
    ungroup %>%
    mutate(Person = as.numeric(factor(Person)),
           Counterpart = as.numeric(factor(Counterpart)))
  nodes = data.frame("name" = 
                       c(sort(unique(events$Person)),
                         sort(unique(events$Counterpart))))
  
  # Replacer
  replacer <- function(x){
    out <- data.frame(x = nodes$name, y = (1:nrow(nodes))-1)
    x <- data.frame(x = x)
    out <- left_join(x, out)
    return(out$y)
  }
  links = bind_rows(
    # Person to counterpart
    events %>% group_by(Person, Counterpart) %>%
      tally %>%
      ungroup %>%
      mutate(Person = replacer(Person),
             Counterpart = replacer(Counterpart)) %>%
      rename(a = Person,
             b = Counterpart)
  )
  
  # Each row represents a link. The first number represents the node being conntected from. 
  # The second number represents the node connected to.
  # The third number is the value of the node
  names(links) = c("source", "target", "value")
  nd3::sankeyNetwork(Links = links, Nodes = nodes,
                     Source = "source", Target = "target",
                     Value = "value", NodeID = "name",
                     fontSize= 12, nodeWidth = 30)
}


# Define function for filtering events
filter_events <- function(events,
                          person = NULL,
                          organization = NULL,
                          city = NULL,
                          country = NULL,
                          counterpart = NULL,
                          visit_start = NULL,
                          visit_end = NULL,
                          month = NULL,
                          search = NULL){
  x <- events
  
  # filter for person
  if(!is.null(person)){
    x <- x %>% filter(Person %in% person)
  }
  # filter for organization
  if(!is.null(organization)){
    x <- x %>% filter(Organization %in% organization)
  }
  # filter for city
  if(!is.null(city)){
    x <- x %>% filter(`City of visit` %in% city)
  }
  # filter for country
  if(!is.null(country)){
    x <- x %>% filter(`Country of visit` %in% country)
  }
  # filter for counterpart
  if(!is.null(counterpart)){
    x <- x %>% filter(Counterpart %in% counterpart)
  }
  # filter for visit start
  if(!is.null(visit_start)){
    x <- x %>% filter(`Visit start` >= visit_start)
  }
  # filter for visit end
  if(!is.null(visit_end)){
    x <- x %>% filter(`Visit end`<= visit_end)
  }
  # filter for month
  if(!is.null(month)){
    x <- x %>% filter(format(`Visit end`, '%B') %in% month |
                        format(`Visit start`, '%B') %in% month)
  }
  # filter for search
  if(!is.null(search)){
    keeps <- apply(mutate_all(.tbl = x, .funs = function(x){grepl(tolower(search), tolower(x))}),1, any)
    x <- x[keeps,]
  }
  return(x)
}

# Calendar, modified from https://github.com/jayjacobs/ggcal/blob/master/R/ggcal.R
gg_cal <- function(dates, fills) {
  # get ordered vector of month names
  months <- format(seq(as.Date("2016-01-01"), as.Date("2016-12-01"), by="1 month"), "%B")
  
  # get lower and upper bound to fill in missing values
  mindate <- as.Date(format(min(dates), "%Y-%m-01"))
  maxdate <- (seq(as.Date(format(max(dates), "%Y-%m-01")), length.out = 2, by="1 month")-1)[2]
  # set up tibble with all the dates.
  filler <- tibble(date = seq(mindate, maxdate, by="1 day"))
  
  t1 <- tibble(date = dates, fill=fills) %>%
    right_join(filler, by="date") %>% # fill in missing dates with NA
    mutate(dow = as.numeric(format(date, "%w"))) %>%
    mutate(month = format(date, "%B")) %>%
    mutate(woy = as.numeric(format(date, "%U"))) %>%
    mutate(year = as.numeric(format(date, "%Y"))) %>%
    mutate(month = factor(month, levels=months, ordered=TRUE)) %>%
    arrange(year, month) %>%
    mutate(monlabel=month)
  
  if (length(unique(t1$year))>1) { # multi-year data set
    t1$monlabel <- paste(t1$month, t1$year)
  }
  
  t2 <- t1 %>%
    mutate(monlabel = factor(monlabel, ordered=TRUE)) %>%
    mutate(monlabel = fct_inorder(monlabel)) %>%
    mutate(monthweek = woy-min(woy),
           y=max(monthweek)-monthweek+1)
  
  weekdays <- c("S", "M", "T", "W", "T", "F", "S")
  ggplot(t2, aes(dow, y, fill=fill)) +
    geom_tile(color="gray80") +
    facet_wrap(~monlabel, ncol=4, scales="free") +
    scale_x_continuous(expand=c(0,0), position="top",
                       breaks=seq(0,6), labels=weekdays) +
    scale_y_continuous(expand=c(0,0)) +
    theme(panel.background=element_rect(fill=NA, color=NA),
          strip.background = element_rect(fill=NA, color=NA),
          strip.text.x = element_text(hjust=0, face="bold"),
          # legend.title = element_blank(),
          axis.ticks=element_blank(),
          axis.title=element_blank(),
          axis.text.y = element_blank(),
          strip.placement = "outsite")
}

make_nd3 <- function (Links, Nodes, Source, Target, Value, NodeID, NodeGroup = NodeID, 
                 LinkGroup = NULL, units = "", colourScale = JS("d3.scaleOrdinal(d3.schemeCategory20);"), 
                 fontSize = 7, fontFamily = NULL, nodeWidth = 15, nodePadding = 10, 
                 margin = NULL, height = NULL, width = NULL, iterations = 32, 
                 sinksRight = TRUE) 
{
  check_zero(Links[, Source], Links[, Target])
  colourScale <- as.character(colourScale)
  Links <- tbl_df_strip(Links)
  Nodes <- tbl_df_strip(Nodes)
  if (!is.data.frame(Links)) {
    stop("Links must be a data frame class object.")
  }
  if (!is.data.frame(Nodes)) {
    stop("Nodes must be a data frame class object.")
  }
  if (missing(Source)) 
    Source = 1
  if (missing(Target)) 
    Target = 2
  if (missing(Value)) {
    LinksDF <- data.frame(Links[, Source], Links[, Target])
    names(LinksDF) <- c("source", "target")
  }
  else if (!missing(Value)) {
    LinksDF <- data.frame(Links[, Source], Links[, Target], 
                          Links[, Value])
    names(LinksDF) <- c("source", "target", "value")
  }
  if (missing(NodeID)) 
    NodeID = 1
  NodesDF <- data.frame(Nodes[, NodeID])
  names(NodesDF) <- c("name")
  if (is.character(NodeGroup)) {
    NodesDF$group <- Nodes[, NodeGroup]
  }
  if (is.character(LinkGroup)) {
    LinksDF$group <- Links[, LinkGroup]
  }
  margin <- margin_handler(margin)
  options = list(NodeID = NodeID, NodeGroup = NodeGroup, LinkGroup = LinkGroup, 
                 colourScale = colourScale, fontSize = fontSize, fontFamily = fontFamily, 
                 nodeWidth = nodeWidth, nodePadding = nodePadding, units = units, 
                 margin = margin, iterations = iterations, sinksRight = sinksRight)
  htmlwidgets::createWidget(name = "sankeyNetwork", x = list(links = LinksDF, 
                                                             nodes = NodesDF, options = options), width = width, height = height, 
                            htmlwidgets::sizingPolicy(padding = 10, browser.fill = TRUE), 
                            package = "nd3")
}
